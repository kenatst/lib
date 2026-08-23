import SwiftUI

// MARK: - WelcomeView — the opening
//
// Premium first impression: wordmark, one charged line, the almost-touching
// motif breathing behind everything, a single CTA. No feature list, no
// carousel. Editorial restraint.

struct WelcomeView: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    var body: some View {
        ZStack {
            // The motif lives behind and above the text — charged negative space.
            VStack {
                SketchMotifView(journey: .theirDesire, evolution: 0.12)
                    .frame(width: 300, height: 340)
                    .opacity(appeared ? 0.85 : 0)
                    .offset(y: appeared ? 0 : 14)
                Spacer()
            }
            .padding(.top, Spacing.xxl)

            VStack(spacing: 0) {
                Spacer()
                Text("EMBER")
                    .font(Typography.editorial(.largeTitle))
                    .kerning(10)
                    .foregroundStyle(Palette.ink)
                    .padding(.bottom, Spacing.md)

                Text("welcome.tagline")
                    .font(Typography.editorial(.title3))
                    .italic()
                    .foregroundStyle(Palette.wine)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Spacing.lg)

                Text("welcome.sub")
                    .emberCaption()
                    .padding(.top, Spacing.sm)

                Spacer()

                VStack(spacing: Spacing.md) {
                    EmberButton(title: String(localized: "welcome.cta")) {
                        Haptics.selection()
                        router.navigate(to: .journeySelection)
                    }

                    Text("welcome.note")
                        .emberCaption()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.lg)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }
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
}
