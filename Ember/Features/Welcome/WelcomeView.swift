import SwiftUI

struct WelcomeView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Text(verbatim: "Ember")
                .font(Typography.editorial(.largeTitle))
                .foregroundStyle(Palette.ink)

            VStack(spacing: Spacing.sm) {
                ForEach(DesireIntention.allCases) { intention in
                    Button {
                        Haptics.selection()
                        router.navigate(to: .intentionOverview(intention))
                    } label: {
                        IntentionRow(intention: intention)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, Spacing.xl)
        .padding(.horizontal, Spacing.md)
        .background(Palette.canvas)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct IntentionRow: View {

    let intention: DesireIntention

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(intention.displayName)
                .font(Typography.editorial(.title3))
                .foregroundStyle(Palette.ink)

            Text(intention.tagline)
                .font(Typography.ui(.subheadline))
                .foregroundStyle(Palette.wine)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(Spacing.md)
        .background(
            Palette.blush,
            in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
        )
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
    .environment(AppRouter())
}
