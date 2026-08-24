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

                EditorialDivider()
                    .frame(width: 54)
                    .padding(.top, Spacing.lg)

                ForEach(Array(DesireIntention.allCases.enumerated()), id: \.element) { index, intention in
                    JourneyOption(intention: intention, index: index, delay: 0.15 + Double(index) * 0.14)
                        .padding(.top, index == 0 ? Spacing.md : Spacing.sm)
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
    let index: Int
    let delay: TimeInterval

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    private var scene: EditorialSketchScene {
        switch intention {
        case .myDesire: return .handOnHeart
        case .theirDesire: return .profiles
        case .ourDesire: return .almostTouching
        }
    }

    private var wash: Color {
        switch intention {
        case .myDesire: return Palette.paper
        case .theirDesire: return Palette.blush
        case .ourDesire: return Palette.softRose.opacity(0.72)
        }
    }

    var body: some View {
        Button {
            Haptics.selection()
            router.navigate(to: .onboarding(intention))
        } label: {
            HStack(alignment: .center, spacing: Spacing.md) {
                if index.isMultiple(of: 2) { artwork }
                copy
                if !index.isMultiple(of: 2) { artwork }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Spacing.sm)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Palette.hairline).frame(height: 1)
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

    private var artwork: some View {
        EditorialSketchView(
            scene: scene,
            color: Palette.intentionTint(intention),
            wash: wash,
            lineWidth: 1.45
        )
        .frame(width: 112, height: 138)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(intention.displayName)
                .font(Typography.editorial(.title2))
                .foregroundStyle(Palette.ink)

            Text(intention.tagline)
                .font(Typography.editorial(.callout))
                .italic()
                .foregroundStyle(Palette.wine)
                .fixedSize(horizontal: false, vertical: true)

            if intention == .theirDesire {
                Text("selection.their.note")
                    .emberCaption()
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                Text("selection.begin")
                    .font(Typography.ui(.caption, weight: .medium))
                    .foregroundStyle(Palette.wine)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Palette.rose)
            }
            .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
