import SwiftUI

// MARK: - RootView
//
// Owns the single NavigationStack and maps typed routes to destinations.
// Route→view mapping lives here so deep links can be added without redesign.

struct RootView: View {

    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch appState.phase {
            case .firstRun:
                WelcomeView()
                    .transition(.opacity)
            case .active:
                navigationStack
                    .transition(.opacity)
            }
        }
        .animation(Motion.resolved(Motion.breathe, reduceMotion: reduceMotion), value: appState.phase)
        .background(PaperBackground())
    }

    @ViewBuilder
    private var navigationStack: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self, destination: destination)
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .journeySelection:
            JourneySelectionView()
        case .onboarding(let intention):
            OnboardingView(intention: intention)
        case .desireProfile:
            DesireProfileView()
        case .home:
            HomeView()
        case .day(let number):
            DailySessionView(dayNumber: number)
        case .eveningReturn(let dayNumber):
            EveningReturnView(dayNumber: dayNumber)
        case .progress:
            ProgressArcView()
        case .journal:
            JournalView()
        case .settings:
            SettingsView()
        case .coupleSetup:
            CoupleSetupView()
        case .coupleSpace:
            CoupleSpaceView()
        }
    }
}

#Preview {
    RootView()
        .environment(EmberStore())
        .environment(AppState())
        .environment(AppRouter())
}
