import Foundation

// MARK: - String resolution helper
//
// All dynamic copy (keys built at runtime, formatted values) MUST resolve
// through these helpers — passing a key String directly to `Text` renders it
// verbatim. Static literals may stay as Text("literal.key").

extension String {

    /// Resolves a localization key from the String Catalog.
    static func ember(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    /// Resolves a localization key and formats arguments into it.
    static func ember(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String.localizedStringWithFormat(format, args)
    }
}
