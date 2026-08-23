import Testing
@testable import Ember

@MainActor
@Suite("App State")
struct AppStateTests {

    @Test("A fresh install begins at the age gate")
    func freshInstall() {
        #expect(AppState(hasJourney: false).phase == .ageGate)
        #expect(AppState(hasJourney: false, ageConfirmed: true).phase == .firstRun)
    }

    @Test("Completing onboarding activates the core experience exactly once")
    func activation() {
        let state = AppState(hasJourney: false)
        state.activate()
        state.activate()
        #expect(state.phase == .active)
    }

    @Test("An existing journey resumes directly in the active experience")
    func resume() {
        #expect(AppState(hasJourney: true).phase == .active)
    }

    @Test("Reset returns to the welcome arc after deletion")
    func reset() {
        let state = AppState(hasJourney: true)
        state.resetToFirstRun()
        // Deletion also erases the age confirmation.
        #expect(state.phase == .ageGate)
    }
}
