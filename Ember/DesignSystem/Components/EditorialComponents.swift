import SwiftUI

// MARK: - Editorial primitives
//
// Small, deliberately opinionated pieces shared across EMBER's narrative
// screens. They create rhythm without turning every passage into a card.

struct SectionEyebrow: View {
    let key: String
    var color: Color = Palette.rose

    var body: some View {
        Text(String.ember(key))
            .font(Typography.ui(.caption, weight: .semibold))
            .foregroundStyle(color)
            .kerning(2.3)
            .textCase(.uppercase)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct EditorialDivider: View {
    var color: Color = Palette.softRose
    var width: CGFloat = 54

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height * 0.55))
            path.addCurve(
                to: CGPoint(x: min(width, size.width), y: size.height * 0.48),
                control1: CGPoint(x: width * 0.28, y: size.height * 0.28),
                control2: CGPoint(x: width * 0.7, y: size.height * 0.72)
            )
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.25, lineCap: .round))
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

struct DailyStepIndicator: View {
    let steps: [String]
    var currentIndex: Int?

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, key in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Capsule()
                            .fill(markColor(for: index))
                            .frame(width: currentIndex == index ? 22 : 8, height: 3)
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(Palette.hairline)
                                .frame(height: 1)
                        }
                    }

                    Text(String.ember(key))
                        .font(Typography.ui(.caption2, weight: currentIndex == index ? .semibold : .regular))
                        .foregroundStyle(currentIndex == index ? Palette.wine : Palette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func markColor(for index: Int) -> Color {
        guard let currentIndex else { return index == 0 ? Palette.wine : Palette.rose }
        return index <= currentIndex ? Palette.wine : Palette.blush
    }
}

struct QuietOption: View {
    let textKey: String
    var isSelected = false
    var mark: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                if let mark {
                    Text(mark)
                        .font(Typography.editorial(.callout))
                        .foregroundStyle(isSelected ? Palette.wine : Palette.rose)
                        .frame(width: 22, alignment: .leading)
                } else {
                    Circle()
                        .stroke(isSelected ? Palette.wine : Palette.rose, lineWidth: 1.25)
                        .frame(width: 10, height: 10)
                        .overlay {
                            Circle()
                                .fill(Palette.wine)
                                .frame(width: 5, height: 5)
                                .opacity(isSelected ? 1 : 0)
                        }
                }

                Text(String(localized: String.LocalizationValue(textKey)))
                    .font(Typography.editorial(.body))
                    .foregroundStyle(isSelected ? Palette.wine : Palette.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, isSelected ? Spacing.sm : 0)
            .background(alignment: .leading) {
                if isSelected {
                    Rectangle()
                        .fill(Palette.blush.opacity(0.52))
                        .overlay(alignment: .leading) {
                            Rectangle().fill(Palette.wine).frame(width: 2)
                        }
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(Palette.hairline).frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct PaperField: View {
    let placeholderKey: String
    @Binding var text: String
    var lineLimit: ClosedRange<Int> = 3...6

    var body: some View {
        TextField(
            String(localized: String.LocalizationValue(placeholderKey)),
            text: $text,
            axis: .vertical
        )
        .lineLimit(lineLimit)
        .font(Typography.editorial(.body))
        .foregroundStyle(Palette.ink)
        .scrollContentBackground(.hidden)
        .padding(.vertical, Spacing.md)
        .padding(.leading, Spacing.md)
        .padding(.trailing, Spacing.sm)
        .background {
            Rectangle()
                .fill(Palette.cream.opacity(0.86))
                .overlay(alignment: .leading) {
                    Rectangle().fill(Palette.softRose).frame(width: 2)
                }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.hairline).frame(height: 1)
        }
        .autocorrectionDisabled(true)
        .textInputAutocapitalization(.sentences)
        .textContentType(nil)
        .privacySensitive()
    }
}

struct InkWashShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.2))
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.03, y: rect.minY + rect.height * 0.12),
            control1: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY - rect.height * 0.02),
            control2: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.minY + rect.height * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.maxY - rect.height * 0.08),
            control1: CGPoint(x: rect.maxX + rect.width * 0.02, y: rect.minY + rect.height * 0.42),
            control2: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.maxY - rect.height * 0.22)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.maxY - rect.height * 0.18),
            control1: CGPoint(x: rect.minX + rect.width * 0.68, y: rect.maxY + rect.height * 0.02),
            control2: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.maxY - rect.height * 0.06)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.2),
            control1: CGPoint(x: rect.minX - rect.width * 0.02, y: rect.maxY - rect.height * 0.48),
            control2: CGPoint(x: rect.minX + rect.width * 0.02, y: rect.minY + rect.height * 0.34)
        )
        return path
    }
}
