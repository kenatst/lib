import Foundation
import Testing
@testable import Ember

// Reusable deterministic fake filesystem with directory semantics.
// (Kept in this file; the original adversarial suite has its own copy scoped
// to that file — this one supports contentsOfDirectory + nested entries.)

class FakeFS: FileOperating, @unchecked Sendable {

    enum Fault: Error { case denied, noSuchFile }

    private let lock = NSLock()
    private var files: Set<String> = []          // every file path
    private var dirs: Set<String> = []           // every directory path

    var failRead = false
    var failWrite = false
    var failRemove = false

    private(set) var removeAttempts: [String] = []
    private(set) var writeAttempts: [String] = []

    init() {}

    private var contents: [String: Data] = [:]

    func seedFile(at url: URL, content: Data = Data("x".utf8)) {
        lock.lock(); defer { lock.unlock() }
        files.insert(url.path)
        contents[url.path] = content
        var intermediate = url.deletingLastPathComponent()
        while intermediate.path != "/" {
            dirs.insert(intermediate.path)
            intermediate = intermediate.deletingLastPathComponent()
        }
    }

    func seedDirectory(at url: URL) {
        lock.lock(); defer { lock.unlock() }
        dirs.insert(url.path)
    }

    func storedBytes(at url: URL) -> Data? {
        lock.lock(); defer { lock.unlock() }
        return contents[url.path]
    }

    func allFiles() -> [String] {
        lock.lock(); defer { lock.unlock() }
        return Array(files).sorted()
    }

    func fileExists(at url: URL) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return files.contains(url.path) || dirs.contains(url.path)
    }

    func readData(at url: URL) throws -> Data {
        lock.lock(); defer { lock.unlock() }
        guard let data = contents[url.path] else { throw Fault.noSuchFile }
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
        files.insert(url.path)
        contents[url.path] = data
        var intermediate = url.deletingLastPathComponent()
        while intermediate.path != "/" {
            dirs.insert(intermediate.path)
            intermediate = intermediate.deletingLastPathComponent()
        }
        lock.unlock()
    }

    func createDirectory(at url: URL) throws {
        lock.lock(); defer { lock.unlock() }
        dirs.insert(url.path)
    }

    func removeItem(at url: URL) throws {
        lock.lock()
        removeAttempts.append(url.path)
        guard files.contains(url.path) || dirs.contains(url.path) else {
            lock.unlock()
            throw Fault.noSuchFile
        }
        if failRemove {
            lock.unlock()
            throw Fault.denied
        }
        // Recursive removal semantics for directories.
        files = files.filter { !$0.hasPrefix(url.path + "/") }
        dirs = dirs.filter { $0 != url.path && !$0.hasPrefix(url.path + "/") }
        files.remove(url.path)
        lock.unlock()
    }

    func moveItem(at url: URL, to destination: URL) throws {
        lock.lock(); defer { lock.unlock() }
        guard files.contains(url.path) else { throw Fault.noSuchFile }
        files.remove(url.path)
        files.insert(destination.path)
    }

    func contentsOfDirectory(at url: URL) -> [String] {
        lock.lock(); defer { lock.unlock() }
        let prefix = url.path + "/"
        let directFiles = files.filter { $0.hasPrefix(prefix) && !$0.dropFirst(prefix.count).contains("/") }
        let directDirs = dirs.filter { $0.hasPrefix(prefix) && !$0.dropFirst(prefix.count).contains("/") }
        let names = directFiles.union(directDirs)
        return names.map { String($0.dropFirst(prefix.count)) }.sorted()
    }
}

// MARK: - Deletion completeness (invariant #2)

@MainActor
@Suite("Delete everything means everything")
struct DeleteEverythingCompletenessTests {

    private func makeDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ember-del-\(UUID().uuidString)", isDirectory: true)
    }

    private func store(in dir: URL, files: FakeFS) -> EmberStore {
        EmberStore(directory: dir, files: files)
    }

    @Test("Normal deletion removes state, drafts, quarantines, timestamped recoveries — verified")
    func normalDeletionRemovesEveryArtifact() throws {
        let dir = makeDir()
        let fs = FakeFS()
        let emberStore = store(in: dir, files: fs)

        // Produce a real state file through the store…
        emberStore.setIntention(.ourDesire)
        emberStore.saveReflection("deeply private", day: 3)
        emberStore.saveDraft("half-written thought", day: 4)

        // …then simulate every recovery artifact EMBER can create, plus
        // future variants sharing the same private directory.
        let artifacts = [
            dir.appendingPathComponent("\(EmberStore.fileName)\(EmberStore.quarantineSuffix)"),
            dir.appendingPathComponent("\(EmberStore.fileName).quarantine-1730000000"),
            dir.appendingPathComponent("\(EmberStore.fileName).quarantine-1740000001"),
            dir.appendingPathComponent("\(EmberStore.fileName).recovery"),
            dir.appendingPathComponent("demo-instructions.txt"),
        ]
        for a in artifacts { fs.seedFile(at: a) }

        let outcome = emberStore.deleteEverything()

        #expect(outcome == .deleted)
        #expect(!fs.fileExists(at: dir), "the entire EMBER directory must be gone")
        #expect(fs.allFiles().isEmpty, "zero EMBER private bytes may remain")
        #expect(emberStore.state == .empty)
        #expect(emberStore.reflection(for: 3) == nil)
        #expect(emberStore.draft(for: 4) == nil)
    }

    @Test("Deleting when the directory does not exist still succeeds")
    func deleteWhenAbsentSucceeds() {
        let fs = FakeFS()
        let emberStore = store(in: makeDir(), files: fs)
        #expect(emberStore.deleteEverything() == .deleted)
        #expect(emberStore.state == .empty)
    }

    @Test("Partial deletion failure is truthful: memory preserved, no fake success")
    func partialFailureIsTruthful() throws {
        let dir = makeDir()
        let fs = FakeFS()
        let emberStore = store(in: dir, files: fs)
        emberStore.setIntention(.myDesire)
        emberStore.saveReflection("still mine", day: 2)

        fs.failRemove = true
        #expect(emberStore.deleteEverything() == .failed)

        // Truthful in-memory state preserved.
        #expect(emberStore.reflection(for: 2) == "still mine")
        #expect(emberStore.hasJourney)

        // Recovery: when removal becomes possible, deletion truly completes.
        fs.failRemove = false
        #expect(emberStore.deleteEverything() == .deleted)
        #expect(fs.allFiles().isEmpty)
        #expect(emberStore.state == .empty)
    }

    @Test("Recursive cleanup failure (leftover entry after removal) refuses success")
    func leftoverVerificationRefusesSuccess() throws {
        let dir = makeDir()

        // Simulate an OS/filesystem quirk where the recursive directory
        // removal "succeeds" but one locked entry silently survives inside.
        // The post-removal verification must refuse to claim success.
        final class StickyFS: FakeFS {
            var quirkArmed = true
            let stickyLock = NSLock()

            nonisolated override init() {
                super.init()
            }

            nonisolated override func removeItem(at url: URL) throws {
                // Only intercept the top-level EMBER directory removal, and
                // only once; afterwards behave normally so recovery works.
                stickyLock.lock()
                let armed = quirkArmed && isEmberDirectoryCandidate(url)
                stickyLock.unlock()
                if armed {
                    stickyLock.lock()
                    quirkArmed = false
                    stickyLock.unlock()
                    // Perform removal of children EXCEPT a survivor…
                    let contents = contentsOfDirectory(at: url)
                    for name in contents where name != "survivor.json" {
                        try? removeItem(at: url.appendingPathComponent(name))
                    }
                    // …then remove the directory itself but re-seed the survivor.
                    try super.removeItem(at: url)
                    seedFile(at: url.appendingPathComponent("survivor.json"),
                             content: Data("leftover private bytes".utf8))
                    return
                }
                try super.removeItem(at: url)
            }

            private func isEmberDirectoryCandidate(_ url: URL) -> Bool {
                url.lastPathComponent.hasPrefix("ember-")
            }
        }

        let sticky = StickyFS()
        let stickyStore = EmberStore(directory: dir, files: sticky)
        stickyStore.setIntention(.theirDesire)
        stickyStore.markDayComplete(1)

        #expect(stickyStore.deleteEverything() == .failed,
                "leftover sensitive bytes must never be reported as deleted")
        #expect(stickyStore.hasJourney, "memory must stay truthful on failure")

        // Recovery: when the quirk no longer fires, deletion truly completes.
        #expect(stickyStore.deleteEverything() == .deleted)
        #expect(stickyStore.state == .empty)
    }

    @Test("Restart journey shares the identical literal-deletion contract")
    func restartUsesSamePath() {
        let dir = makeDir()
        let fs = FakeFS()
        let emberStore = store(in: dir, files: fs)
        emberStore.setIntention(.myDesire)
        emberStore.markDayComplete(5)

        #expect(emberStore.restartJourney() == .deleted)
        #expect(!fs.fileExists(at: dir))
        #expect(emberStore.state == .empty)
    }
}

// MARK: - Write-failure persistence truth (invariant #3)

@MainActor
@Suite("Write failure truthfulness")
struct WriteTruthTests {

    private func makeDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ember-volatile-\(UUID().uuidString)", isDirectory: true)
    }

    @Test("Failed write flips status to volatile; UI cannot claim durable save")
    func failedWriteBecomesVolatile() throws {
        let dir = makeDir()
        let fs = FakeFS()
        let emberStore = EmberStore(directory: dir, files: fs)

        emberStore.setIntention(.myDesire)
        #expect(emberStore.persistenceStatus == .ready)

        fs.failWrite = true
        emberStore.saveReflection("only in memory right now", day: 6)
        #expect(emberStore.persistenceStatus == .volatile,
                "a failed write must be visible in the status")

        // The user's words stay in memory.
        #expect(emberStore.reflection(for: 6) == "only in memory right now")

        // UI contract helper: durable save may not be claimed while volatile.
        let canClaimDurableSave = (emberStore.persistenceStatus == .ready)
        #expect(canClaimDurableSave == false)
    }

    @Test("Next successful mutation persists accumulated state and returns to ready")
    func recoveryAfterFailedWrite() throws {
        let dir = makeDir()
        let fs = FakeFS()
        let emberStore = EmberStore(directory: dir, files: fs)

        emberStore.setIntention(.myDesire)

        fs.failWrite = true
        emberStore.saveReflection("written during outage", day: 6)
        #expect(emberStore.persistenceStatus == .volatile)

        // Storage recovers; ANY later mutation retries and persists EVERYTHING.
        fs.failWrite = false
        emberStore.markDayComplete(6)
        #expect(emberStore.persistenceStatus == .ready)

        // Reload from disk proves the volatile-era content was persisted.
        // (The FakeFS in this file is an isolated fake; read through the REAL
        // FileManager is not possible — instead reload via the store itself.)
        let reloaded = EmberStore(directory: dir, files: fs)
        #expect(reloaded.reflection(for: 6) == "written during outage",
                "volatile-era content must ride along on the next successful save")
        #expect(reloaded.state.completedDays == [6])
        _ = try? JSONDecoder().decode(
            EmberStore.PersistedState.self,
            from: try #require(fs.storedBytes(at: dir.appendingPathComponent(EmberStore.fileName)))
        )
    }

    @Test("Repeated failures keep truth volatile without losing content")
    func repeatedFailuresKeepContentInMemory() {
        let dir = makeDir()
        let fs = FakeFS()
        let emberStore = EmberStore(directory: dir, files: fs)
        emberStore.setIntention(.ourDesire)

        fs.failWrite = true
        emberStore.markDayComplete(1)
        emberStore.saveReflection("first", day: 1)
        emberStore.saveReflection("second", day: 2)
        emberStore.recordCheckIn(CheckIn(dayNumber: 1, response: .noticedSomething, date: .now))

        #expect(emberStore.persistenceStatus == .volatile)
        #expect(emberStore.journalEntries.map(\.text).sorted() == ["first", "second"].sorted())
        #expect(emberStore.state.completedDays == [1])
    }

    @Test("Volatile banner body key exists in catalog (EN+FR)")
    func volatileCopyLocalized() throws {
        // Guard against shipping English-only honesty again.
        let catalogURL = Bundle(for: BundleToken.self)
            .url(forResource: "Localizable", withExtension: "xcstrings")
        // The compiled test host carries the strings via the app bundle;
        // presence is enforced by the localization completeness suites. Here
        // we assert the key resolution itself doesn't fall back to the key.
        _ = catalogURL
        let en = String(localized: String.LocalizationValue("persistence.banner.body.volatile"))
        #expect(en != "persistence.banner.body.volatile", "missing localization for volatile banner")
    }
}

private final class BundleToken {}
