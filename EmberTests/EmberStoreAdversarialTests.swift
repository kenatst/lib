import Foundation
import Testing
@testable import Ember

// MARK: - Deterministic fake filesystem
//
// Just enough surface to reproduce absence / unreadability / corruption /
// deletion failure without flaky real-FS gymnastics. Records every attempted
// mutation so tests can prove EMBER never touches disk when it must not.

private final class FakeFiles: FileOperating, @unchecked Sendable {

    enum Fault: Error { case denied, noSuchFile }

    private let lock = NSLock()
    private var storage: [String: Data] = [:]
    private var directories: Set<String> = []

    // Failure injection
    var failRead = false
    var failWrite = false
    var failRemove = false

    // Attempt records (recorded even when the operation fails)
    private(set) var writeAttempts: [String] = []
    private(set) var removeAttempts: [String] = []
    private(set) var moveAttempts: [(from: String, to: String)] = []
    private(set) var directoryCreations: [String] = []

    init(_ initial: [String: Data] = [:]) {
        storage = initial
        for path in initial.keys {
            trackAncestors(path)
        }
    }

    /// Records ancestor directories so fileExists(directory) works like a real FS.
    private func trackAncestors(_ path: String) {
        var parent = URL(fileURLWithPath: path).deletingLastPathComponent()
        while parent.path != "/" {
            directories.insert(parent.path)
            parent = parent.deletingLastPathComponent()
        }
    }

    func put(_ data: Data, at url: URL) {
        lock.lock(); defer { lock.unlock() }
        storage[url.path] = data
        trackAncestors(url.path)
    }
    func peek(_ url: URL) -> Data? {
        lock.lock(); defer { lock.unlock() }
        return storage[url.path]
    }

    func fileExists(at url: URL) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return storage[url.path] != nil || directories.contains(url.path)
    }

    func readData(at url: URL) throws -> Data {
        lock.lock(); defer { lock.unlock() }
        guard let data = storage[url.path] else { throw Fault.noSuchFile }
        if failRead { throw Fault.denied }
        return data
    }

    func write(_ data: Data, to url: URL) throws {
        lock.lock()
        writeAttempts.append(url.path)
        if failWrite {
            lock.unlock()
            throw Fault.denied
        }
        storage[url.path] = data
        trackAncestors(url.path)
        lock.unlock()
    }

    func createDirectory(at url: URL) throws {
        lock.lock(); defer { lock.unlock() }
        directoryCreations.append(url.path)
        directories.insert(url.path)
        var parent = url.deletingLastPathComponent()
        while parent.path != "/" {
            directories.insert(parent.path)
            parent = parent.deletingLastPathComponent()
        }
    }

    func removeItem(at url: URL) throws {
        lock.lock()
        removeAttempts.append(url.path)
        let isFile = storage[url.path] != nil
        let isDir = directories.contains(url.path)
        guard isFile || isDir else {
            lock.unlock()
            throw Fault.noSuchFile
        }
        if failRemove {
            lock.unlock()
            throw Fault.denied
        }
        // Recursive semantics for directories.
        let prefix = url.path + "/"
        storage = storage.filter { !$0.key.hasPrefix(prefix) }
        directories = directories.filter { $0 != url.path && !$0.hasPrefix(prefix) }
        storage.removeValue(forKey: url.path)
        lock.unlock()
    }

    func moveItem(at url: URL, to destination: URL) throws {
        lock.lock()
        moveAttempts.append((url.path, destination.path))
        guard let data = storage[url.path] else {
            lock.unlock()
            throw Fault.noSuchFile
        }
        storage.removeValue(forKey: url.path)
        storage[destination.path] = data
        lock.unlock()
    }

    func contentsOfDirectory(at url: URL) -> [String] {
        lock.lock(); defer { lock.unlock() }
        let prefix = url.path + "/"
        var names = Set(storage.keys.filter { $0.hasPrefix(prefix) })
        names.formUnion(directories.filter { $0.hasPrefix(prefix) })
        return names
            .filter { !$0.dropFirst(prefix.count).contains("/") }
            .map { String($0.dropFirst(prefix.count)) }
            .sorted()
    }
}

// MARK: - Adversarial persistence tests

@MainActor
@Suite("EmberStore adversarial persistence")
struct EmberStoreAdversarialTests {

    private func makeDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ember-at-\(UUID().uuidString)", isDirectory: true)
    }

    private var stateURL: URL { makeDir().appendingPathComponent(EmberStore.fileName) }

    @Test("Absent file is a legitimate fresh install: ready and writable")
    func absentIsFreshInstall() throws {
        let dir = makeDir()
        let files = FakeFiles()
        let store = EmberStore(directory: dir, files: files)

        #expect(store.persistenceStatus == .ready)
        #expect(store.state == .empty)

        store.setIntention(.myDesire)
        #expect(files.writeAttempts.count >= 1, "a fresh install must be allowed to initialize storage")

        // Reload over the same directory restores what was written.
        let reloaded = EmberStore(directory: dir, files: FakeFiles([dir.appendingPathComponent(EmberStore.fileName).path: files.peek(dir.appendingPathComponent(EmberStore.fileName))!]))
        #expect(reloaded.state.intention == .myDesire)
        #expect(reloaded.persistenceStatus == .ready)
    }

    @Test("Present-but-unreadable file: no disk mutation, all writes refused, recovery replaces placeholder")
    func unreadableBlocksEverythingUntilRecoverable() throws {
        let dir = makeDir()
        let fileURL = dir.appendingPathComponent(EmberStore.fileName)

        // A REAL previous session's state, now unreadable (device locked).
        var previous = EmberStore.PersistedState.empty
        previous.ageConfirmed = true
        previous.intention = .theirDesire
        previous.completedDays = [1, 2, 3]
        let realBytes = try JSONEncoder().encode(previous)

        let files = FakeFiles([fileURL.path: realBytes])
        files.failRead = true

        let store = EmberStore(directory: dir, files: files)
        #expect(store.persistenceStatus == .unavailable(.unreadable))
        #expect(store.state == .empty, "placeholder only — never the real state")

        // Every mutation path refuses to touch disk.
        store.setAgeConfirmed()
        store.setIntention(.myDesire)
        store.markDayComplete(9)
        store.saveReflection("typed while locked", day: 4)
        #expect(files.writeAttempts.isEmpty, "saving over an unreadable protected file destroys private data")
        #expect(files.removeAttempts.isEmpty)
        #expect(files.moveAttempts.isEmpty)
        #expect(files.peek(fileURL) == realBytes, "the real file must remain byte-for-byte intact")

        // Deletion is still honest: removing an unreadable file IS possible…
        // but this test's subject is recovery, so restore readability instead.
        files.failRead = false
        store.retryLoading()

        #expect(store.persistenceStatus == .ready)
        #expect(store.state.intention == .theirDesire, "recovery must load the REAL state wholesale")
        #expect(store.state.completedDays == [1, 2, 3])

        // Now writes work and go to disk.
        store.setIntention(.myDesire)
        #expect(files.writeAttempts.count >= 1)
    }

    @Test("Corrupt file: quarantined byte-for-byte, writes blocked in-process, quarantine survives")
    func corruptFileIsQuarantinedNotDestroyed() throws {
        let dir = makeDir()
        let fileURL = dir.appendingPathComponent(EmberStore.fileName)
        let quarantineURL = dir.appendingPathComponent(EmberStore.fileName + EmberStore.quarantineSuffix)
        let corruptedBytes = Data("{ this was once someone's private journey".utf8)

        let files = FakeFiles([fileURL.path: corruptedBytes])
        let store = EmberStore(directory: dir, files: files)

        #expect(store.persistenceStatus == .unavailable(.corruptQuarantined))
        #expect(files.moveAttempts.contains { $0.to == quarantineURL.path }, "corrupt content must be moved aside, never deleted")
        #expect(files.peek(quarantineURL) == corruptedBytes, "quarantine preserves every recoverable byte")
        #expect(files.peek(fileURL) == nil)

        // Writes stay blocked while the situation is unresolved in-process.
        store.setIntention(.myDesire)
        #expect(files.writeAttempts.isEmpty)

        // Recovery pass: main file is gone (quarantined), so a deliberate
        // retry starts clean — while the quarantine file remains on disk.
        store.retryLoading()
        #expect(store.persistenceStatus == .ready)
        #expect(store.state == .empty)
        #expect(fileExists(quarantineURL, in: files))
    }

    @Test("A second quarantine never destroys the first")
    func doubleQuarantineKeepsBoth() throws {
        let dir = makeDir()
        let fileURL = dir.appendingPathComponent(EmberStore.fileName)
        let stamp = Int(Date().timeIntervalSince1970)
        let stampedURL = dir.appendingPathComponent("\(EmberStore.fileName).quarantine-\(stamp)")

        let files = FakeFiles([
            fileURL.path: Data("broken one".utf8),
            stampedURL.path: Data("an earlier quarantine".utf8),
        ])

        _ = EmberStore(directory: dir, files: files)

        #expect(files.peek(stampedURL) == Data("an earlier quarantine".utf8), "pre-existing quarantine must survive")
        #expect(files.moveAttempts.contains { $0.to != stampedURL.path && $0.from == fileURL.path })
    }

    @Test("Deletion failure reports failure and leaves memory AND disk untouched")
    func deletionFailureIsTruthful() throws {
        let dir = makeDir()
        let files = FakeFiles()
        let store = EmberStore(directory: dir, files: files)

        store.setIntention(.ourDesire)
        store.saveReflection("still mine", day: 7)
        let savedBytes = files.peek(dir.appendingPathComponent(EmberStore.fileName))

        files.failRemove = true
        let outcome = store.deleteEverything()

        #expect(outcome == .failed)
        #expect(store.state.intention == .ourDesire, "on failure the UI must stay in the real journey")
        #expect(store.reflection(for: 7) == "still mine", "private words must never vanish on a failed promise")
        #expect(store.hasJourney)
        #expect(files.peek(dir.appendingPathComponent(EmberStore.fileName)) == savedBytes, "disk untouched by the failed attempt")

        // Restart shares the identical truthful contract.
        #expect(store.restartJourney() == .failed)
        #expect(store.reflection(for: 7) == "still mine")

        // When removal becomes possible again, deletion truly completes —
        // and it removes the ENTIRE private directory, verified.
        files.failRemove = false
        #expect(store.deleteEverything() == .deleted)
        #expect(store.state == .empty)
        #expect(!files.fileExists(at: dir))
        #expect(files.contentsOfDirectory(at: dir).isEmpty)
    }

    @Test("Deleting when nothing exists still succeeds (fresh-install idempotence)")
    func deleteWhenAbsentSucceeds() {
        let files = FakeFiles()
        let store = EmberStore(directory: makeDir(), files: files)

        #expect(store.deleteEverything() == .deleted)
        #expect(store.restartJourney() == .deleted)
        #expect(store.state == .empty)
    }

    @Test("Failed save does not flip readiness; successful save resumes")
    func transientSaveFailureKeepsState() throws {
        let dir = makeDir()
        let files = FakeFiles()
        let store = EmberStore(directory: dir, files: files)

        files.failWrite = true
        store.setIntention(.myDesire)
        #expect(store.persistenceStatus == .volatile,
                "a failed write must be visible — UI cannot claim a durable save")

        files.failWrite = false
        store.markDayComplete(1)
        #expect(store.persistenceStatus == .ready, "next successful write restores readiness")
        #expect(files.writeAttempts.count >= 2, "next mutation retries the write")

        let bytes = try #require(files.peek(dir.appendingPathComponent(EmberStore.fileName)))
        let decoded = try JSONDecoder().decode(EmberStore.PersistedState.self, from: bytes)
        #expect(decoded.intention == .myDesire)
        #expect(decoded.completedDays == [1])
    }

    @Test("Legacy single-space reflections migrate into their owner's space")
    func legacyReflectionMigration() throws {
        let dir = makeDir()
        let fileURL = dir.appendingPathComponent(EmberStore.fileName)

        var legacy = EmberStore.PersistedState.empty
        legacy.schemaVersion = 1
        legacy.intention = .myDesire
        legacy.reflections = [3: "from the days before spaces"]
        let bytes = try JSONEncoder().encode(legacy)

        let store = EmberStore(directory: dir, files: FakeFiles([fileURL.path: bytes]))

        #expect(store.persistenceStatus == .ready)
        #expect(store.reflection(for: 3) == "from the days before spaces")
        #expect(store.journalEntries.count == 1)
        #expect(store.state.reflections.isEmpty, "legacy field drained after migration")
        #expect(store.state.reflectionsBySpace["solo"]?[3] == "from the days before spaces")
    }

    private func fileExists(_ url: URL, in files: FakeFiles) -> Bool {
        files.fileExists(at: url)
    }
}
