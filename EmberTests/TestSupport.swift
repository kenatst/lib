import Foundation

// MARK: - Test support
//
// The test target is TEST_HOSTed inside Ember.app, so there is no generated
// `Bundle.module`. These helpers look resources up in the host app bundle.

private final class TestBundleAnchor {}

enum TestBundles {
    /// The host application bundle (contains compiled Localizable.strings).
    static var app: Bundle { Bundle(identifier: "com.kenatst.ember") ?? Bundle(for: TestBundleAnchor.self) }
}

// MARK: - Compiled strings access
//
// Xcode compiles the String Catalog (xcstrings) into per-language
// .lproj/Localizable.strings inside the host app bundle.

enum CompiledStrings {

    static func load(language: String = "en") throws -> [String: String] {
        let bundle = TestBundles.app
        guard let lprojPath = bundle.path(forResource: language, ofType: "lproj"),
              let lproj = Bundle(path: lprojPath),
              let stringsPath = lproj.path(forResource: "Localizable", ofType: "strings"),
              let dict = NSDictionary(contentsOf: URL(fileURLWithPath: stringsPath)) as? [String: String] else {
            throw NSError(
                domain: "EmberTests",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Localizable.strings (\(language)) missing from app bundle"]
            )
        }
        return dict
    }

    /// Both shipped languages, for key-parity assertions.
    static func loadAll() throws -> (english: [String: String], french: [String: String]) {
        (try load(language: "en"), try load(language: "fr"))
    }
}
