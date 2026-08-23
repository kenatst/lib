import Foundation
import Testing
@testable import Ember

// MARK: - Onboarding branching & profile derivation

@Suite("Onboarding & Desire Profile")
struct OnboardingProfileTests {

    private func responses(_ pairs: [(Onboarding.QuestionID, Onboarding.OptionID)]) -> Onboarding.Responses {
        var r = Onboarding.Responses()
        for (q, o) in pairs { r.record(.init(questionID: q, optionID: o)) }
        return r
    }

    @Test("Question sets branch by journey")
    func branching() {
        #expect(Onboarding.questions(for: .myDesire).map(\.id) == [.duration, .stress, .myState, .mySelfConnection, .myPressure])
        #expect(Onboarding.questions(for: .theirDesire).map(\.id) == [.duration, .theirConnection, .theirSeen, .theirVoice])
        #expect(Onboarding.questions(for: .ourDesire).map(\.id) == [.duration, .ourRhythm, .ourTouch, .ourCuriosity])
        // No question appears twice in any set.
        for intention in DesireIntention.allCases {
            let ids = Onboarding.questions(for: intention).map(\.id)
            #expect(Set(ids).count == ids.count)
        }
    }

    @Test("Every question option resolves to a dimension with a nonzero-range score")
    func optionsResolve() {
        for intention in DesireIntention.allCases {
            for question in Onboarding.questions(for: intention) {
                #expect(question.options.count == 4)
                for option in question.options {
                    let resolved = Onboarding.Responses.lookup(question: question.id, option: option.id)
                    #expect(resolved != nil)
                    #expect(resolved?.dimension == option.dimension)
                }
            }
        }
    }

    @Test("Recording the same question twice replaces without duplicating order")
    func recordingReplaces() {
        var r = Onboarding.Responses()
        r.record(.init(questionID: .duration, optionID: .weeks))
        r.record(.init(questionID: .duration, optionID: .months))
        #expect(r.count == 1)
        #expect(r.order == [.duration])
        #expect(r.option(for: .duration)?.id == .months)
    }

    @Test("Strong anticipation answers rank anticipation first")
    func derivationRanksDominantFirst() {
        let r = responses([
            (.duration, .months),                  // novelty 0
            (.myState, .longingWithoutShape),      // anticipation +2
            (.mySelfConnection, .atEaseDistant),   // selfConnection -2
            (.stress, .stressHeavy),               // emotionalSafety -2
        ])
        let profile = DesireProfileDeriver.derive(from: r, intention: .myDesire)
        // The single strongest signal (anticipation, |1|) ranks first; ties
        // break by declaration order deterministically.
        #expect(profile.readings.first?.dimension == .anticipation)
        #expect(profile.reading(.anticipation)?.band == .rich)
        #expect(profile.reading(.emotionalSafety)?.band == .guarded)
        #expect(profile.reading(.selfConnection)?.band == .guarded)
        #expect(profile.dominant.first == .anticipation)
    }

    @Test("Derivation is deterministic")
    func deterministic() {
        let r = responses([
            (.duration, .creptUp),
            (.stress, .stressSome),
            (.myState, .flicker),
            (.mySelfConnection, .atEasePassing),
            (.myPressure, .pressureHope),
        ])
        #expect(DesireProfileDeriver.derive(from: r, intention: .myDesire)
            == DesireProfileDeriver.derive(from: r, intention: .myDesire))
    }

    @Test("Empty answers produce an empty but valid profile")
    func emptyAnswers() {
        let profile = DesireProfileDeriver.derive(from: Onboarding.Responses(), intention: .ourDesire)
        #expect(profile.readings.isEmpty)
        #expect(profile.dominant.isEmpty)
    }

    @Test("Bands map monotonically to strength")
    func bands() {
        func band(strength: Double) -> DimensionReading.Band {
            DimensionReading(dimension: .novelty, strength: strength).band
        }
        #expect(band(strength: -1) == .guarded)
        #expect(band(strength: -0.3) == .guarded)
        #expect(band(strength: 0) == .middle)
        #expect(band(strength: 0.34) == .middle)
        #expect(band(strength: 0.36) == .rich)
        #expect(band(strength: 1) == .rich)
    }

    @Test("Codable round trip preserves profile")
    func codable() throws {
        let r = responses([(.duration, .months), (.ourTouch, .touchAlive)])
        let profile = DesireProfileDeriver.derive(from: r, intention: .ourDesire)
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(DesireProfile.self, from: data)
        #expect(decoded == profile)
    }
}

// MARK: - Journey catalog

@Suite("Journey Catalog")
struct JourneyCatalogTests {

    @Test("Catalog holds exactly 21 sequential days across 3 weeks")
    func testDays() {
        #expect(JourneyCatalog.totalDays == 21)
        #expect(JourneyCatalog.allDays.count == 21)
        #expect(JourneyCatalog.allDays.map(\.number) == Array(1...21))
        #expect(Set(JourneyCatalog.allDays.map(\.week)) == Set([1, 2, 3]))
        #expect(JourneyCatalog.day(1)?.week == 1)
        #expect(JourneyCatalog.day(7)?.week == 1)
        #expect(JourneyCatalog.day(8)?.week == 2)
        #expect(JourneyCatalog.day(15)?.week == 3)
        #expect(JourneyCatalog.day(0) == nil)
        #expect(JourneyCatalog.day(22) == nil)
    }

    @Test("Evolution spans 0 to 1 across the journey")
    func evolution() {
        #expect(JourneyCatalog.day(1)?.evolution == 0)
        #expect(abs((JourneyCatalog.day(11)?.evolution ?? -1) - 0.5) < 0.001)
        #expect(JourneyCatalog.day(21)?.evolution == 1)
    }

    @Test("Every day's localization keys exist in the String Catalog")
    func keysExist() throws {
        let catalog = try CompiledStringsTests.load()

        for intention in DesireIntention.allCases {
            for question in Onboarding.questions(for: intention) {
                #expect(catalog[question.textKey] != nil, "missing \(question.textKey)")
                for option in question.options {
                    #expect(catalog[option.textKey] != nil, "missing \(option.textKey)")
                }
            }
        }
        for day in JourneyCatalog.allDays {
            for key in [day.titleKey, day.discoverKey, day.returnPromptKey] {
                #expect(catalog[key] != nil, "missing \(key)")
            }
            // Theme pools: every reflect/act variant this day could serve,
            // across all three journeys' offsets and the emphasized variant.
            for offset in 0...2 {
                #expect(catalog[day.reflectKey(offset: offset)] != nil,
                        "missing \(day.reflectKey(offset: offset))")
                #expect(catalog[day.actKey(offset: offset)] != nil,
                        "missing \(day.actKey(offset: offset))")
            }
            #expect(catalog[day.reflectKey(emphasizing: true)] != nil)
            #expect(catalog[day.actKey(emphasizing: true)] != nil)
        }
        // Couple asymmetric steps for both roles on all days.
        for dayNumber in 1...21 {
            for role in EmberStore.CoupleRole.allCases {
                let key = "couple.asymmetric.day.\(dayNumber).\(role.rawValue)"
                #expect(catalog[key] != nil, "missing \(key)")
            }
        }
    }
}

/// Loads the compiled strings tables from the host app bundle. Xcode compiles
/// the String Catalog (xcstrings) into Localizable.strings at build time.
enum CompiledStringsTests {
    static func load(language: String = "en") throws -> [String: String] {
        guard let lprojPath = TestBundles.app.path(forResource: language, ofType: "lproj"),
              let lproj = Bundle(path: lprojPath),
              let stringsPath = lproj.path(forResource: "Localizable", ofType: "strings"),
              let dict = NSDictionary(contentsOf: URL(fileURLWithPath: stringsPath)) as? [String: String] else {
            throw NSError(domain: "EmberTests", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Localizable.strings (\(language)) missing from app bundle"])
        }
        return dict
    }

    /// Both shipped languages must contain the same key set.
    static func loadAll() throws -> (english: [String: String], french: [String: String]) {
        (try load(language: "en"), try load(language: "fr"))
    }
}
