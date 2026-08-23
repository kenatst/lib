import SwiftUI

// MARK: - Editorial text helpers
// Small wrappers so narrative copy is consistent and VoiceOver-friendly.

extension Text {
    /// Large editorial headline.
    func emberTitle() -> some View {
        font(Typography.editorial(.title))
            .foregroundStyle(Palette.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Narrative body in serif — the reading voice of EMBER.
    func emberProse(_ style: Font.TextStyle = .body, color: Color = Palette.ink) -> some View {
        font(Typography.editorial(style))
            .foregroundStyle(color)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Small UI caption in sans.
    func emberCaption(_ color: Color = Palette.mutedInk) -> some View {
        font(Typography.ui(.footnote))
            .foregroundStyle(color)
            .kerning(0.2)
    }
}

/// A serif pull-quote used for discover cards and profile lines.
struct EditorialQuote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Typography.editorial(.title3))
            .italic()
            .foregroundStyle(Palette.wine)
            .lineSpacing(7)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isStaticText)
    }
}
