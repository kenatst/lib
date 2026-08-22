import Testing
@testable import Ember

@MainActor
struct AppStateTests {

    @Test("A fresh install begins in onboarding")
    func freshAppStateStartsInOnboarding() {
        let appState = AppState()
        #expect(appState.phase == .onboarding)
    }

    @Test("Completing onboarding activates the core experience exactly once")
    func completingOnboardingActivatesCoreExperience() {
        let appState = AppState()
        appState.completeOnboarding()
        #expect(appState.phase == .active)
    }
}
