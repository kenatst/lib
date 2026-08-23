import SwiftUI

// MARK: - JourneySelectionView
//
// "What do you want back?" — three pulls, deliberately NOT three identical
// cards: each journey gets its own motif, its own composition weight, and a
// staggered editorial layout. Selection advances to adaptive onboarding.

struct JourneySelectionView: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("selection.title")
                    .font(Typography.editorial(.largeTitle))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, Spacing.xl)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                Text("selection.subtitle")
                    .emberProse(.callout, color: Palette.mutedInk)
                    .padding(.top, Spacing.sm)
                    .padding(.trailing, Spacing.xl)
                    .opacity(appeared ? 1 : 0)

                ForEach(Array(DesireIntention.allCases.enumerated()), id: \.element) { index, intention in
                    JourneyOption(intention: intention, delay: 0.15 + Double(index) * 0.14)
                        .padding(.top, Spacing.lg)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationBarHidden(true)
        .onAppear {
            guard !appeared else { return }
            withAnimation(Motion.resolved(Motion.ink, reduceMotion: reduceMotion, delay: 0.05)) {
                appeared = true
            }
        }
    }
}

// MARK: - One option

private struct JourneyOption: View {

    let intention: DesireIntention
    let delay: TimeInterval

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    /// Editorial asymmetry: each row indents differently.
    private var leadingInset: CGFloat {
        switch intention {
        case .myDesire: return 0
        case .theirDesire: return Spacing.lg
        case .ourDesire: return Spacing.sm
        }
    }

    var body: some View {
        Button {
            Haptics.selection()
            router.navigate(to: .onboarding(intention))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                SketchMotifView(
                    journey: intention,
                    evolution: 0.08,
                    strokeColor: Palette.intentionTint(intention),
                    lineWidth: 1.9
                )
                .frame(width: 132, height: 150)
                .frame(maxWidth: .infinity, alignment: intention == .myDesire ? .leading : .trailing)

                Text(intention.displayNameKey)
                    .font(Typography.editorial(.title2))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, Spacing.sm)

                Text(intention.taglineKey)
                    .font(Typography.editorial(.callout))
                    .italic()
                    .foregroundStyle(Palette.wine)
                    .padding(.top, 4)

                if intention == .theirDesire {
                    Text("selection.their.note")
                        .emberCaption()
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Spacing.xs)
                }

                Path { path in
                    path.move(to: CGPoint(x: 0, y: 6))
                    path.addLine(to: CGPoint(x: 44, y: 6))
                }
                .stroke(Palette.softRose, style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                .padding(.top, Spacing.sm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, leadingInset)
            .padding(Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(Palette.cream.opacity(0.72))
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("selection.begin"))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            guard !appeared else { return }
            withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion, delay: delay)) {
                appeared = true
            }
        }
    }
}

extension DesireIntention {
    var displayNameKey: String { "intention.\(rawValue).name" }
    var taglineKey: String { "intention.\(rawValue).tagline" }
}

// MARK: - Shared press feedback (quiet scale, no bounce)

struct PressableStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        JourneySelectionView()
    }
    .environment(AppRouter())
}
