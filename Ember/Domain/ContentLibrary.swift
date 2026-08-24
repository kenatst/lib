import Foundation

// MARK: - ContentUnit
//
// One individually addressable piece of editorial content. Stable IDs only —
// never localized strings. The String Catalog resolves IDs to copy at render.
//
// The original 21-day authored arc is the SEED of this library: each legacy
// day contributes its discover/reflect/act/return copy as first-class units
// alongside the theme-pool variants. Nothing was thrown away; everything got
// an address.

nonisolated enum Movement: String, Codable, CaseIterable, Sendable {
    case discover
    case reflect
    case act
    case returnPrompt = "return"
}

nonisolated struct ContentID: Equatable, Hashable, Sendable, Codable {
    /// Canonical key into the String Catalog, e.g. "theme.discover.body.2".
    let key: String

    init(_ key: String) { self.key = key }

    var localizationKey: String { key }
}

nonisolated struct ContentUnit: Equatable, Sendable {
    let id: ContentID
    let movement: Movement
    let theme: DayTheme
    /// Which intentions this unit may serve. Empty = all.
    let eligibleIntentions: Set<DesireIntention>
    /// Gentle units suit reduced dose; deeper ones fit raised. Empty = any.
    let intensityBand: Set<DailyEngine.Intensity>
    /// Cooldown in days before this exact unit may serve again.
    let cooldownDays: Int
}

// MARK: - Library

nonisolated enum ContentLibrary {

    /// All units EMBER can draw from. Built from the authored catalog:
    ///   * 21 legacy day-arcs (day.N.*) — the original written journey,
    ///   * theme pools ×3 for title/discover/reflect/act, ×2 for return,
    ///   * couple asymmetric pairs (OUR DESIRE only).
    nonisolated static func allUnits() -> [ContentUnit] {
        var units: [ContentUnit] = []

        // Theme-pool units — the backbone of ongoing daily variety.
        for theme in DayTheme.allCases {
            for variant in 1...3 {
                units.append(unit("theme.title.\(theme.rawValue).\(variant)", movement: .discover, theme: theme))
                units.append(unit("theme.discover.\(theme.rawValue).\(variant)", movement: .discover, theme: theme))
                units.append(unit("theme.reflect.\(theme.rawValue).\(variant)", movement: .reflect, theme: theme))
                units.append(unit("theme.act.\(theme.rawValue).\(variant)", movement: .act, theme: theme))
            }
            for variant in 1...2 {
                units.append(unit("theme.return.\(theme.rawValue).\(variant)", movement: .returnPrompt, theme: theme))
            }
        }

        // Legacy day-arc units — the authored 21-day voice, kept addressable
        // so long-term users still meet the original writing periodically.
        for day in 1...21 {
            units.append(unit("day.\(day).title", movement: .discover, theme: JourneyCatalog.day(day)?.theme ?? .attention))
            units.append(unit("day.\(day).discover", movement: .discover, theme: JourneyCatalog.day(day)?.theme ?? .attention))
            units.append(unit("day.\(day).reflect", movement: .reflect, theme: JourneyCatalog.day(day)?.theme ?? .attention))
            units.append(unit("day.\(day).act", movement: .act, theme: JourneyCatalog.day(day)?.theme ?? .attention))
            units.append(unit("day.\(day).return", movement: .returnPrompt, theme: JourneyCatalog.day(day)?.theme ?? .attention))
        }

        return units
    }

    private static func unit(_ key: String, movement: Movement, theme: DayTheme) -> ContentUnit {
        ContentUnit(
            id: ContentID(key),
            movement: movement,
            theme: theme,
            eligibleIntentions: [],
            intensityBand: [],
            cooldownDays: defaultCooldown(for: movement)
        )
    }

    /// Discover ideas linger longest; acts need the most breathing room.
    nonisolated static func defaultCooldown(for movement: Movement) -> Int {
        switch movement {
        case .discover: 30      // an idea shouldn't repeat within a month
        case .reflect: 14
        case .act: 21
        case .returnPrompt: 10
        }
    }

    /// Lookup: all units for one movement + theme.
    nonisolated static func units(movement: Movement, theme: DayTheme) -> [ContentUnit] {
        allUnits().filter { $0.movement == movement && $0.theme == theme }
    }

    /// Is a unit eligible today given what the user has already seen?
    nonisolated static func isEligible(
        _ unit: ContentUnit,
        on today: LocalDay,
        history: [DailySessionRecord],
        intention: DesireIntention
    ) -> Bool {
        if !unit.eligibleIntentions.isEmpty && !unit.eligibleIntentions.contains(intention) {
            return false
        }
        // Exact-content cooldown: find the most recent serving of this ID.
        for record in history.reversed() {
            guard record.day.days(since: today) <= unit.cooldownDays * 2 else { break }
            if record.servedIDs.contains(unit.id.key) {
                return record.day.days(since: today) > unit.cooldownDays
            }
        }
        return true
    }
}
