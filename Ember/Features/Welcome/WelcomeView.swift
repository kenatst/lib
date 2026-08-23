import SwiftUI

// MARK: - WelcomeView — the opening
//
// Premium first impression: the almost-touching motif holds the upper field,
// the wordmark stands alone (nothing crosses it), one charged line, a single
// CTA. Editorial restraint; generous negative space.

struct WelcomeView: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Motif: high in the frame, cropped softly at the leading edge.
                SketchMotifView(journey: .theirDesire, evolution: 0.1)
                    .frame(width: proxy.size.width * 1.05, height: 330)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .offset(y: -60)
                    .opacity(appeared ? 0.75 : 0)

                VStack(spacing: 0) {
                    Spacer()
                        .frame(maxHeight: proxy.size.height * 0.30)

                    Text("EMBER")
                        .font(Typography.editorial(.largeTitle))
                        .kerning(12)
                        .foregroundStyle(Palette.wine)
                        .padding(.leading, 12)   // optically recenter tracked caps

                    Text("welcome.tagline")
                        .font(Typography.editorial(.title3))
                        .italic()
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)

                    Text("welcome.sub")
                        .emberProse(.subheadline, color: Palette.mutedInk)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xs)

                    Spacer()

                    VStack(spacing: Spacing.lg) {
                        EmberButton(title: String(localized: "welcome.cta")) {
                            Haptics.selection()
                            router.navigate(to: .journeySelection)
                        }

                        Text("welcome.note")
                            .emberCaption()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .padding(.bottom, Spacing.xl)
                }
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
