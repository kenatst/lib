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
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    SectionEyebrow(key: "agegate.eyebrow")
                        .padding(.top, Spacing.xl)

                    EditorialSketchView(scene: .threshold, wash: Palette.paper, lineWidth: 1.45)
                        .frame(height: min(210, proxy.size.height * 0.27))
                        .padding(.horizontal, Spacing.xl)

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

                    Spacer(minLength: Spacing.xl)

                    VStack(spacing: Spacing.md) {
                        Toggle(isOn: $confirmed) {
                            Text(String.ember("agegate.confirm"))
                                .font(Typography.ui(.body))
                                .foregroundStyle(Palette.ink)
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
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
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
