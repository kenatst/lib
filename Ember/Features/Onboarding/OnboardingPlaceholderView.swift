import SwiftUI

struct OnboardingPlaceholderView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("onboarding.title")
                .font(Typography.editorial(.largeTitle))
                .foregroundStyle(Palette.ink)

            Button(String(localized: "onboarding.action.continue")) {
                appState.completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.canvas)
    }
}

#Preview {
    OnboardingPlaceholderView()
        .environment(AppState())
}
