import SwiftUI

// MARK: - Semantic palette
//
// EMBER's identity: warm cream canvas, blush and rose mid-tones, wine and ink
// for weight. All colors are semantic tokens; never use raw values in features.

enum Palette {

    // Canvas & paper
    static let canvas = Color(hex: 0xFFF8F5)
    static let paper = Color(hex: 0xFFF0EE)
    static let cream = Color(hex: 0xFFFCFA)

    // Mid tones
    static let blush = Color(hex: 0xF3D9DE)
    static let softRose = Color(hex: 0xEAB8C3)
    static let rose = Color(hex: 0xD7869A)

    // Weight
    static let wine = Color(hex: 0x6A243B)
    static let deepWine = Color(hex: 0x4A182A)

    // Text
    static let ink = Color(hex: 0x28171E)
    static let mutedInk = Color(hex: 0x705861)

    // Derived semantic roles
    static let hairline = softRose.opacity(0.55)

    /// The accent used for interactive elements.
    static let accent = wine

    /// Per-journey tint, used sparingly (motif strokes, small marks).
    static func intentionTint(_ intention: DesireIntention) -> Color {
        switch intention {
        case .myDesire: rose
        case .theirDesire: softRose
        case .ourDesire: wine
        }
    }
}

extension Color {
    init(hex: UInt64) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
