import Foundation
import Testing
@testable import Ember

// MARK: - EmberStore: persistence, privacy boundaries, deletion

@MainActor
@Suite("EmberStore")
struct EmberStoreTests {

    private func makeStore() -> EmberStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ember-tests-\(UUID().uuidString)", isDirectory: true)
        return EmberStore(directory: dir)
    }

    @Test("Fresh store is empty and has no journey")
    func fresh() {
        let store = makeStore()
        #expect(store.state == .empty)
        #expect(!store.hasJourney)
    }

    @Test("State mutations persist to disk and reload")
    func persistsAndReloads() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ember-tests-\(UUID().uuidString)", isDirectory: true)

        do {
            let store = EmberStore(directory: dir)
            store.setIntention(.theirDesire)
            var responses = Onboarding.Responses()
            responses.record(.init(questionID: .duration, optionID: .aYearOrMore))
            responses.record(.init(questionID: .theirSeen, optionID: .feelInvisible))
            store.recordResponses(responses)
            store.setProfile(DesireProfileDeriver.derive(from: responses, intention: .theirDesire))
            store.markDayComplete(1)
            store.markDayComplete(2)
            store.saveReflection("kept on this device", day: 2)
        }

        // A new instance over the same directory must restore everything.
        let reloaded = EmberStore(directory: dir)
        #expect(reloaded.state.intention == .theirDesire)
        #expect(reloaded.state.responses?.count == 2)
        #expect(reloaded.state.profile?.intention == .theirDesire)
        #expect(reloaded.state.completedDays == [1, 2])
        #expect(reloaded.reflection(for: 2) == "kept on this device")
    }

    @Test("Duplicate day completion is idempotent and stays sorted")
    func idempotentDays() {
        let store = makeStore()
        store.markDayComplete(3)
        store.markDayComplete(1)
        store.markDayComplete(3)
        #expect(store.state.completedDays == [1, 3])
    }

    @Test("Progress counts lived sessions, not merely generated plans")
    func generatedPlanDoesNotInflateProgress() {
        let store = makeStore()
        store.setIntention(.myDesire)
        _ = store.planForToday()

        #expect(store.state.sessionHistory.count == 1)
        #expect(store.countCompletedSessions() == 0)

        store.markMovement(.discover)
        #expect(store.countCompletedSessions() == 0)

        store.completeTodaySession()
        #expect(store.countCompletedSessions() == 1)
    }

    @Test("Check-in replaces the same day and keeps chronological order")
    func checkIns() {
        let store = makeStore()
        store.recordCheckIn(CheckIn(dayNumber: 2, response: .feltDifferent, date: .now))
        store.recordCheckIn(CheckIn(dayNumber: 1, response: .nothingChanged, date: .now))
        store.recordCheckIn(CheckIn(dayNumber: 2, response: .wantMore, date: .now))
        #expect(store.state.checkIns.map(\.dayNumber) == [1, 2])
        #expect(store.state.checkIns.last { $0.dayNumber == 2 }?.response == .wantMore)
    }

    @Test("deleteEverything erases memory AND the file on disk")
    func deletion() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ember-tests-\(UUID().uuidString)", isDirectory: true)
        let store = EmberStore(directory: dir)
        store.setIntention(.ourDesire)
        store.saveReflection("deeply private", day: 4)

        let fileURL = dir.appendingPathComponent(EmberStore.fileName)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        store.deleteEverything()

        #expect(store.state == .empty)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        #expect(store.reflection(for: 4) == nil)
    }

    // MARK: Couple privacy — the binding rules

    @Test("A partner can never read the other's reflections; only explicit hand-offs exist")
    func couplePrivacy() {
        let store = makeStore()
        store.setCoupleRole(.partnerOne)

        // Partner One writes a PRIVATE reflection (never visible to partner two).
        store.saveReflection("my most private thought", day: 5)

        // The only cross-partner channel is an explicit hand-off.
        store.handOffNote("a note I chose to give you", from: .partnerOne)

        // Partner Two can receive the handed-off note…
        #expect(store.takeHandedOffNote(for: .partnerTwo) == "a note I chose to give you")

        // …but there is no path to Partner One's private reflection.
        #expect(store.takeHandedOffNote(for: .partnerOne) == nil)

        // Hand-off targets the OTHER partner by construction.
        store.handOffNote("from two", from: .partnerTwo)
        #expect(store.takeHandedOffNote(for: .partnerOne) == "from two")

        // And the private reflection remains untouched and unread by the model.
        #expect(store.reflection(for: 5) == "my most private thought")
    }

    @Test("Roles are strict pairs")
    func roles() {
        #expect(EmberStore.CoupleRole.partnerOne.other == .partnerTwo)
        #expect(EmberStore.CoupleRole.partnerTwo.other == .partnerOne)
    }
}
