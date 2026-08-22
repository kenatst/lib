import SwiftUI

struct IntentionOverviewPlaceholderView: View {

    let intention: DesireIntention

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text(intention.displayName)
                .font(Typography.editorial(.largeTitle))
                .foregroundStyle(Palette.ink)

            Text(intention.tagline)
                .font(Typography.ui(.title3))
                .foregroundStyle(Palette.wine)

            Text("placeholder.notice")
                .font(Typography.ui(.footnote))
                .foregroundStyle(Palette.rose)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.canvas)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        IntentionOverviewPlaceholderView(intention: .ourDesire)
    }
}
