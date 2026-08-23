import SwiftUI

// MARK: - AgeGateView
//
// EMBER speaks about desire with adults. One honest confirmation, once.
// Stored in the private store so it survives relaunches and is erased by
// "Delete everything".

struct AgeGateView: View {

    @Environment(EmberStore.self) private var store
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router

    @State private var confirmed = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("agegate.title")
                .font(Typography.editorial(.largeTitle))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.lg)

            Text("agegate.body")
                .emberProse(.callout, color: Palette.mutedInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.md)

            Spacer()

            VStack(spacing: Spacing.md) {
                Toggle(isOn: $confirmed) {
                    Text(String.ember("agegate.confirm"))
                        .emberProse(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .tint(Palette.wine)

                EmberButton(title: String(localized: "welcome.cta")) {
                    guard confirmed else { return }
                    store.setAgeConfirmed()
                    appState.confirmAge()
                }
                .disabled(!confirmed)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AgeGateView()
        .environment(EmberStore())
        .environment(AppState())
        .environment(AppRouter())
}
