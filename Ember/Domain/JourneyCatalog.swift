import Foundation

// MARK: - Journey content model
//
// A day = Discover (one idea) + Reflect (a themed prompt with a private
// note) + Act (one real-world experiment). The evening Return question is
// theme-keyed too.
//
// Content model discipline:
//   * Discover copy stays DAY-keyed — the ideas read as one written arc.
//   * Reflect / Act / Return are THEME pools (3/3/2 authored variants per
//     theme, EN+FR). Which variant a day serves is deterministic:
//     day number + intention offset. Same day number, different journey →
//     genuinely different practice. Re-themed days stay coherent for free.

nonisolated struct JourneyDay: Identifiable, Hashable, Sendable {
    let number: Int          // 1…21
    let week: Int            // 1…3
    let theme: DayTheme

    var titleKey: String { "day.\(number).title" }
    var discoverKey: String { "day.\(number).discover" }

    /// Deterministic variant selection inside the theme pool.
    /// `offset` differs per intention so journeys diverge in practice.
    /// When the planner currently EMPHASIZES this day's theme (profile
    /// dominance × check-in intensity), serve the deeper authored variant
    /// instead of the rotating one — personalization that changes real copy,
    /// not labels.
    func reflectKey(offset: Int = 0, emphasizing: Bool = false) -> String {
        "theme.reflect.\(theme.rawValue).\(Self.poolIndex(number, modulo: 3, offset: offset, emphasizing: emphasizing))"
    }
    func actKey(offset: Int = 0, emphasizing: Bool = false) -> String {
        "theme.act.\(theme.rawValue).\(Self.poolIndex(number, modulo: 3, offset: offset, emphasizing: emphasizing))"
    }
    var returnPromptKey: String {
        "theme.return.\(theme.rawValue).\(Self.poolIndex(number, modulo: 2, offset: 0, emphasizing: false))"
    }

    private static func poolIndex(_ number: Int, modulo: Int, offset: Int, emphasizing: Bool) -> Int {
        if emphasizing { return modulo }   // the deepest authored variant
        return ((number - 1 + offset) % modulo) + 1
    }

    var id: Int { number }
}

extension DesireIntention {
    /// Per-journey rotation through the theme pools.
    nonisolated var poolOffset: Int {
        switch self {
        case .myDesire: 0
        case .theirDesire: 1
        case .ourDesire: 2
        }
    }
}

nonisolated enum DayTheme: String, Codable, Sendable {
    case attention      // noticing what's already there
    case anticipation   // the approach
    case body           // self-connection, ease
    case novelty        // small departures
    case communication  // words, honesty
    case play           // lightness, curiosity
    case closeness      // emotional connection
    case autonomy       // room to choose
}

// MARK: - Personalization hooks

extension JourneyDay {

    /// Days whose discover/act copy has a variant tuned for a dominant
    /// dimension get key suffix ".for.<dimension>"; the resolver falls back
    /// to the base key. This keeps personalization meaningful but bounded.
    func personalizedDiscoverKey(dominant: Dimension) -> String {
        let variant = "\(discoverKey).for.\(dominant.rawValue)"
        return String(localized: String.LocalizationValue(variant)) == variant ? discoverKey : variant
    }

    /// The journey motif evolution for this day (0…1 across 21 days).
    var evolution: Double {
        Double(number - 1) / 20.0
    }
}

// MARK: - Catalog

nonisolated enum JourneyCatalog {

    static let totalDays = 21

    nonisolated static let allDays: [JourneyDay] = buildDays()

    static func day(_ number: Int) -> JourneyDay? {
        guard number >= 1, number <= totalDays else { return nil }
        return allDays[number - 1]
    }

    /// The day as experienced within a given intention — same number, but
    /// themed by that journey's shape (this is where the three journeys
    /// genuinely diverge in sequence).
    static func day(_ number: Int, for intention: DesireIntention) -> JourneyDay? {
        guard let base = day(number) else { return nil }
        return JourneyDay(
            number: base.number,
            week: base.week,
            theme: JourneyShape.shape(for: intention).theme(for: number)
        )
    }

    static func days(for intention: DesireIntention) -> [JourneyDay] {
        allDays
    }

    // swiftlint:disable:next line_length
    private static let themesByDay: [DayTheme] = [
        .attention, .body, .anticipation,            // week 1 — Noticing
        .attention, .anticipation, .body, .novelty,
        .communication,                              // week 2 — Kindling
        .play, .closeness, .autonomy, .anticipation,
        .novelty, .communication,                    // week 3 — Tending
        .play, .body, .closeness, .attention,
        .autonomy, .anticipation, .closeness,
    ]


    private static func buildDays() -> [JourneyDay] {
        var built: [JourneyDay] = []
        built.reserveCapacity(totalDays)
        for index in 0..<totalDays {
            let number = index + 1
            let week = min(3, index / 7 + 1)
            built.append(
                JourneyDay(
                    number: number,
                    week: week,
                    theme: themesByDay[index]
                )
            )
        }
        return built
    }
}
