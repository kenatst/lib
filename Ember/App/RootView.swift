import SwiftUI

struct RootView: View {

    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch appState.phase {
            case .onboarding:
                OnboardingPlaceholderView()
                    .transition(.opacity)
            case .active:
                navigationStack
                    .transition(.opacity)
            }
        }
        .animation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion), value: appState.phase)
        .background(Palette.canvas)
    }

    private var navigationStack: some View {
        @Bindable var router = router
        return NavigationStack(path: $router.path) {
            WelcomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .intentionOverview(let intention):
                        IntentionOverviewPlaceholderView(intention: intention)
                    }
                }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .environment(AppRouter())
}
