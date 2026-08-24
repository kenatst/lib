import SwiftUI

// MARK: - WelcomeView — the opening
//
// Premium first impression: the almost-touching motif holds the upper field,
// the wordmark stands alone (nothing crosses it), one charged line, a single
// CTA. Editorial restraint; generous negative space.

struct WelcomeView: View {

    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Text("EMBER")
                        .font(Typography.editorial(.largeTitle))
                        .kerning(12)
                        .foregroundStyle(Palette.wine)
                        .padding(.leading, 12)
                        .padding(.top, Spacing.lg)

                    EditorialSketchView(scene: .profiles, wash: Palette.blush, lineWidth: 1.65)
                        .frame(height: min(300, proxy.size.height * 0.34))
                        .padding(.top, Spacing.sm)
                        .opacity(appeared ? 1 : 0)

                    Text("welcome.headline")
                        .font(Typography.editorial(.largeTitle))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Spacing.md)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    Text("welcome.sub")
                        .emberProse(.subheadline, color: Palette.mutedInk)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.xs)

                    EditorialDivider(width: 46)
                        .frame(width: 46)
                        .padding(.top, Spacing.lg)

                    VStack(spacing: Spacing.lg) {
                        EmberButton(title: String(localized: "welcome.cta")) {
                            Haptics.selection()
                            appState.activate()
                            router.setRoot(.journeySelection)
                        }

                        Text("welcome.note")
                            .emberCaption()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .padding(.top, Spacing.xl)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.lg)
                }
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .navigationBarHidden(true)
        .onAppear {
            guard !appeared else { return }
            withAnimation(Motion.resolved(Motion.ink, reduceMotion: reduceMotion)) {
                appeared = true
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environment(AppRouter())
        .environment(AppState(ageConfirmed: true))
}
