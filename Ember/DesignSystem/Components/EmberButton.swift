import SwiftUI

// MARK: - Primary CTA
//
// A quiet, weighted button — deep wine fill, cream serif label. Rectangular
// with gentle corners; no giant pills.

struct EmberButton: View {

    let title: String
    var icon: String?
    var style: Style = .primary
    var isLoading = false
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case quiet
    }

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(Typography.ui(.body, weight: .medium))
                    .kerning(0.3)
                    .foregroundStyle(foreground)
            }
            .foregroundStyle(foreground)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.45)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .disabled(isLoading)
    }

    private var foreground: Color {
        switch style {
        case .primary: Palette.cream
        case .secondary: Palette.wine
        case .quiet: Palette.mutedInk
        }
    }

    private var background: Color {
        switch style {
        case .primary: Palette.wine
        case .secondary: Palette.cream.opacity(0.6)
        case .quiet: .clear
        }
    }

    private var border: Color {
        switch style {
        case .primary: Palette.deepWine.opacity(0.6)
        case .secondary: Palette.softRose
        case .quiet: Palette.hairline
        }
    }
}

// MARK: - Quiet text link used for secondary paths

struct EmberTextLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.ui(.subheadline))
                .foregroundStyle(Palette.mutedInk)
                .underline(true, color: Palette.softRose)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
}

#Preview("Buttons") {
    VStack(spacing: Spacing.sm) {
        EmberButton(title: "Begin") {}
        EmberButton(title: "Continue", style: .secondary) {}
        EmberButton(title: "Not now", style: .quiet) {}
        EmberTextLink(title: "See the shape so far") {}
    }
    .padding(Spacing.md)
    .background(Palette.canvas)
}
