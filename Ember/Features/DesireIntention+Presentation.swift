import SwiftUI

// MARK: - DesireIntention presentation helpers
// UI copy for domain intents lives here; the String Catalog holds the text.

extension DesireIntention {

    /// Localized display name.
    var displayName: String {
        String(localized: String.LocalizationValue(displayNameKey))
    }

    /// Localized promise line.
    var tagline: String {
        String(localized: String.LocalizationValue(taglineKey))
    }
}
