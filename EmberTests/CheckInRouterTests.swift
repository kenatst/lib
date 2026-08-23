import Foundation
import Testing
@testable import Ember

// MARK: - Evening check-in adaptation

@Suite("Check-In Adaptation")
struct CheckInAdapterTests {

    @Test("Nothing changed slows the pace toward attention and body")
    func nothingChanged() {
        let adjustment = CheckInAdapter.adjust(after: .nothingChanged, dayNumber: 4, dominant: [.novelty])
        #expect(adjustment.emphasizeThemes == [.attention, .body])
        #expect(adjustment.pacingNoteKey == "pacing.gentle")
    }

    @Test("Noticed something keeps the thread without forcing themes")
    func noticed() {
        let adjustment = CheckInAdapter.adjust(after: .noticedSomething, dayNumber: 9, dominant: [.connection])
        #expect(adjustment.emphasizeThemes.isEmpty)
        #expect(adjustment.pacingNoteKey == "pacing.thread")
    }

    @Test("Felt different leans into the dominant dimensions' themes")
    func feltDifferent() {
        let adjustment = CheckInAdapter.adjust(after: .feltDifferent, dayNumber: 10, dominant: [.anticipation, .playfulness, .anticipation])
        #expect(adjustment.emphasizeThemes == [.anticipation, .play])
        #expect(adjustment.pacingNoteKey == nil)
    }

    @Test("Want more raises the anticipation dose")
    func wantMore() {
        let adjustment = CheckInAdapter.adjust(after: .wantMore, dayNumber: 12, dominant: [])
        #expect(adjustment.emphasizeThemes == [.anticipation])
        #expect(adjustment.pacingNoteKey == "pacing.dose")
    }

    @Test("Every check-in response and pacing note exists in the String Catalog")
    func localization() throws {
        let catalog = try CompiledStringsTests.load()

        for response in CheckInResponse.allCases {
            #expect(catalog[response.textKey] != nil, "missing \(response.textKey)")
        }
        for key in ["pacing.gentle", "pacing.thread", "pacing.dose"] {
            #expect(catalog[key] != nil, "missing \(key)")
        }
    }
}

// MARK: - AppState pacing

@MainActor
@Suite("AppState pacing")
struct AppStatePacingTests {

    @Test("Next suggested day is one past the highest completed, capped at 21")
    func suggestedDay() {
        let fresh = AppState(hasJourney: false)
        #expect(fresh.suggestedDayNumber(completedDays: []) == 1)
        #expect(fresh.suggestedDayNumber(completedDays: [1, 2, 5]) == 6)
        #expect(fresh.suggestedDayNumber(completedDays: Array(1...21)) == 21)
        #expect(fresh.suggestedDayNumber(completedDays: Array(1...25)) == 21)
    }

    @Test("Phase reflects journey existence and transitions both ways")
    func phases() {
        let fresh = AppState(hasJourney: false)
        #expect(fresh.phase == .firstRun)
        fresh.activate()
        #expect(fresh.phase == .active)
        fresh.resetToFirstRun()
        #expect(fresh.phase == .firstRun)

        let returning = AppState(hasJourney: true)
        #expect(returning.phase == .active)
    }
}

// MARK: - Router

@MainActor
@Suite("AppRouter")
struct AppRouterTests {

    @Test("Typed routes append in order and carry payloads")
    func navigation() {
        let router = AppRouter()
        router.navigate(to: .journeySelection)
        router.navigate(to: .onboarding(.myDesire))
        router.navigate(to: .day(4))
        router.navigate(to: .eveningReturn(4))
        #expect(router.path == [.journeySelection, .onboarding(.myDesire), .day(4), .eveningReturn(4)])
        router.pop()
        #expect(router.path.last == .day(4))
        router.popToRoot()
        #expect(router.path.isEmpty)
        router.pop() // popping empty is a safe no-op
        #expect(router.path.isEmpty)
    }

    @Test("setRoot replaces the whole stack")
    func setRoot() {
        let router = AppRouter()
        router.navigate(to: .journeySelection)
        router.navigate(to: .onboarding(.ourDesire))
        router.setRoot(.home)
        #expect(router.path == [.home])
    }

    @Test("replace swaps the top route in place")
    func replaceTop() {
        let router = AppRouter()
        router.navigate(to: .day(3))
        router.replace(with: .eveningReturn(3))
        #expect(router.path == [.eveningReturn(3)])
        router.replace(with: .home) // on non-empty stack, still swaps top
        #expect(router.path == [.home])
        let empty = AppRouter()
        empty.replace(with: .home)
        #expect(empty.path == [.home])
    }

    @Test("Routes with different payloads stay distinct")
    func payloadIdentity() {
        #expect(AppRoute.day(3) != AppRoute.day(4))
        #expect(AppRoute.onboarding(.myDesire) != AppRoute.onboarding(.theirDesire))
        #expect(AppRoute.day(3) == AppRoute.day(3))
    }
}
