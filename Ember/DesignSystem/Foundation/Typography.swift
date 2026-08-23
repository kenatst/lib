import SwiftUI

// MARK: - Editorial typography
//
// Serif voice = reflection, invitation, narrative (system serif renders as
// New York on iOS — editorial without shipping a font file).
// Sans voice = UI chrome (buttons, captions, controls).
// Both scale automatically with Dynamic Type because they are style-based.

enum Typography {

    /// Editorial serif for narrative copy.
    static func editorial(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .serif, weight: weight)
    }

    /// Editorial serif with italic emphasis.
    static func editorialItalic(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .serif).italic().weight(weight)
    }

    /// Native sans-serif for UI chrome.
    static func ui(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
    }
}
