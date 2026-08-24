import Foundation

// MARK: - Couple space (domain mirror of the store's partner roles)
//
// Kept in the Domain layer so DailyEngine has no dependency on Data.

nonisolated enum CoupleSpace: String, Codable, Sendable {
    case partnerOne
    case partnerTwo

    var other: CoupleSpace { self == .partnerOne ? .partnerTwo : .partnerOne }
}

// MARK: - DailyEngine
//
// The heart of ongoing EMBER. Answers exactly one question:
//
//     "What is the experience for TODAY?"
//
// CONTRACTS:
//   1. IDEMPOTENT: if a plan already exists for today, it is returned
//      untouched. Recommendation runs ONLY when no plan exists yet.
//   2. FROZEN: a created plan never changes — not on reflection edits,
//      not on completions, not on tonight's check-in, not on restarts.
//   3. NO DEBT: missed days create nothing — no backlog, no punishment.
//      A user returning after 60 days simply gets today's plan.
//   4. NO FINITE COMPLETION: the engine plans forever; there is no day 22
//      problem and no terminal state.
//   5. DETERMINISTIC: same inputs (state + calendar) → same plan.
//
// Selection strategy (COHERENCE FIRST):
//   * ONE theme per day; all four movements come from that theme's pools.
//   * Theme choice scores: journey-shape rotation × profile affinity ×
//     learned resonance − theme saturation − recent-theme penalty.
//   * Exact content units respect per-movement cooldowns against history.
//   * OUR DESIRE additionally freezes asymmetric assignments per partner.

nonisolated enum DailyEngine {

    nonisolated enum Intensity: String, Codable, CaseIterable, Sendable {
        case gentle
        case steady
        case deeper

        var scoreBias: Double {
            switch self {
            case .gentle: -1
            case .steady: 0
            case .deeper: 1
            }
        }
    }

    // MARK: Plan ID

    /// Canonical plan/session ID: "<day>#<intention>".
    nonisolated static func planID(day: LocalDay, intention: DesireIntention) -> String {
        "\(day.storageKey)#\(intention.rawValue)"
    }

    // MARK: Dose

    /// Maps the evening-honesty dose (reduced/steady/raised semantics kept)
    /// onto the engine's gentle/steady/deeper vocabulary.
    nonisolated static func intensity(from checkIns: [CheckIn]) -> Intensity {
        guard let last = checkIns.max(by: { $0.dayNumber < $1.dayNumber }) else { return .steady }
        switch last.response {
        case .nothingChanged: return .gentle
        case .wantMore: return .deeper
        case .noticedSomething, .feltDifferent: return .steady
        }
    }

    // MARK: Planning

    /// Returns today's existing plan untouched, or creates one.
    ///
    /// - Parameters:
    ///   - today: canonical local day (injectable for tests/simulations)
    ///   - plans: known frozen plans (persisted store)
    ///   - history: session records (persisted store)
    ///   - signals: learned signals (persisted store)
    static func planForToday(
        today: LocalDay,
        intention: DesireIntention,
        profile: DesireProfile?,
        checkIns: [CheckIn],
        plans: [String: DailyPlan],
        history: [DailySessionRecord],
        signals: LearnedSignals,
        coupleRole: CoupleSpace?
    ) -> DailyPlan {
        let id = planID(day: today, intention: intention)
        if let existing = plans[id] {
            return existing                       // IDEMPOTENT — never re-recommend
        }

        let intensity = self.intensity(from: checkIns)
        let theme = selectTheme(
            intention: intention,
            profile: profile,
            intensity: intensity,
            signals: signals,
            history: history,
            today: today
        )

        let bundle = selectBundle(theme: theme, today: today, history: history, signals: signals)

        var assignments: [CoupleSpace: ContentID]?
        if intention == .ourDesire {
            assignments = coupleAssignments(theme: theme, today: today, role: coupleRole, history: history)
        }

        return DailyPlan(
            id: id,
            day: today,
            intention: intention,
            theme: theme,
            titleContentID: bundle.title,
            discoverContentID: bundle.discover,
            reflectContentID: bundle.reflect,
            actContentID: bundle.act,
            returnPromptID: bundle.returnPrompt,
            intensity: intensity,
            emphasizedThemes: emphasizedThemes(profile: profile, signals: signals),
            coupleAssignmentIDs: assignments,
            createdAt: Date()
        )
    }

    // MARK: Theme selection (explainable)

    nonisolated struct ThemeExplanation: Equatable, Sendable {
        let scores: [DayTheme: Double]
        let chosen: DayTheme
        let excludedByCooldown: [DayTheme]
    }

    private static func selectTheme(
        intention: DesireIntention,
        profile: DesireProfile?,
        intensity: Intensity,
        signals: LearnedSignals,
        history: [DailySessionRecord],
        today: LocalDay
    ) -> DayTheme {

        let shape = JourneyShape.shape(for: intention)
        let dominant = profile?.dominant ?? []
        let guarded = profile?.readings.filter { $0.band == .guarded }.map(\.dimension) ?? []

        // Recent themes (last 4 sessions) get a saturation penalty so the
        // engine cannot loop on one note even when everything else loves it.
        let recentThemes = history.suffix(4).map(\.theme)
        var recencyPenalty: [DayTheme: Double] = [:]
        for (index, theme) in recentThemes.reversed().enumerated() {
            recencyPenalty[theme, default: 0] += 2.2 - Double(index) * 0.55
        }

        // Position within the shape's arc — the engine still walks the authored
        // rhythm as its base pulse, cycling forever after the seed 21 days.
        let seedPosition = seedPosition(forToday: today, history: history, shape: shape)

        var scores: [DayTheme: Double] = [:]
        for theme in DayTheme.allCases {
            var s = 0.0

            // 1. Journey affinity: each intention weights themes differently.
            s += journeyWeight(intention: intention, theme: theme)

            // 2. Arc pulse: the authored sequence still leads the dance when
            //    nothing else pulls. Cycled forever through the seed arc.
            let arcTheme = shape.theme(for: seedPosition)
            if arcTheme == theme { s += 2.5 }

            // 3. Profile prior.
            for dimension in dominant {
                s += ThemeAffinity.weight(dimension: dimension, theme: theme)
            }

            // 4. Learned resonance — slow, bounded evidence from Returns.
            s += SignalUpdater.resonance(for: theme, in: signals)

            // 5. Guarded dimensions lean grounding.
            if !guarded.isEmpty {
                s += groundedAdjustment(theme)
            }

            // 6. Dose bias.
            switch intensity {
            case .gentle:
                if theme == .body || theme == .attention { s += 1 }
                if theme == .novelty || theme == .play { s -= 0.5 }
            case .deeper:
                if theme == .anticipation || theme == .novelty || theme == .play { s += 1 }
            case .steady:
                break
            }

            // 7. Saturation: don't repeat what yesterday and friends just were.
            s -= recencyPenalty[theme, default: 0]

            scores[theme] = s
        }

        return scores.max { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value < rhs.value }
            return lhs.key.rawValue > rhs.key.rawValue   // deterministic tie-break
        }?.key ?? .attention
    }

    /// Which position of the authored seed arc "today" corresponds to:
    /// sessions lived cycle forever through the 21 authored beats, so the
    /// engine never runs out of arc — year three is a new pass through it.
    private static func seedPosition(
        forToday today: LocalDay,
        history: [DailySessionRecord],
        shape: JourneyShape
    ) -> Int {
        let lived = history.filter { $0.intention == shape.intention }.count
        return (lived % JourneyCatalog.totalDays) + 1
    }

    /// Per-intention theme weights — the three journeys remain genuinely
    /// different recommendation spaces.
    nonisolated static func journeyWeight(intention: DesireIntention, theme: DayTheme) -> Double {
        switch intention {
        case .myDesire:
            switch theme {
            case .body: return 2.4
            case .autonomy: return 2.0
            case .attention: return 1.8
            case .anticipation: return 0.8       // self-anticipation only, modest
            case .closeness: return 0.6
            case .communication: return 0.4
            case .novelty: return 0.6
            case .play: return 0.8
            }
        case .theirDesire:
            switch theme {
            case .attention: return 2.2          // feeling seen
            case .communication: return 1.8
            case .body: return 1.4               // confidence/presence
            case .anticipation: return 1.4
            case .novelty: return 1.0
            case .autonomy: return 1.2           // protects against performing
            case .closeness: return 1.0
            case .play: return 0.8
            }
        case .ourDesire:
            switch theme {
            case .communication: return 2.0
            case .closeness: return 1.8
            case .play: return 1.6
            case .novelty: return 1.4
            case .anticipation: return 1.4
            case .autonomy: return 1.2           // two people choosing, freely
            case .attention: return 1.0
            case .body: return 0.8
            }
        }
    }

    private static func groundedAdjustment(_ theme: DayTheme) -> Double {
        var adj = 0.0
        if theme == .novelty || theme == .play || theme == .anticipation { adj -= 1.2 }
        if theme == .closeness || theme == .body || theme == .attention { adj += 0.6 }
        return adj
    }

    private static func emphasizedThemes(profile: DesireProfile?, signals: LearnedSignals) -> [DayTheme] {
        let dominant = Array((profile?.dominant ?? []).prefix(2))
        return DayTheme.allCases
            .map { theme -> (DayTheme, Double) in
                let prior = dominant.reduce(0.0) { $0 + ThemeAffinity.weight(dimension: $1, theme: theme) }
                return (theme, SignalUpdater.resonance(for: theme, in: signals) + prior)
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.rawValue < rhs.0.rawValue
            }
            .prefix(2)
            .map(\.0)
    }

    // MARK: Content bundle selection

    nonisolated struct ContentBundle: Equatable, Sendable {
        let title: ContentID
        let discover: ContentID
        let reflect: ContentID
        let act: ContentID
        let returnPrompt: ContentID
    }

    /// Picks one coherent set of content units for the day's single theme,
    /// honoring exact-content cooldowns against session history. Deterministic
    /// tie-breaks by variant index keep identical state → identical plans.
    private static func selectBundle(
        theme: DayTheme,
        today: LocalDay,
        history: [DailySessionRecord],
        signals: LearnedSignals
    ) -> ContentBundle {
        func lastServedDay(_ key: String) -> Int? {
            // Days since last serving; nil if never served.
            for record in history.reversed() where record.servedIDs.contains(key) {
                return record.day.days(since: today)
            }
            return nil
        }

        func pick(_ movement: Movement, prefixOverride: String? = nil, modulo: Int) -> ContentID {
            let prefix = prefixOverride ?? movement.rawValue
            let candidates = (1...modulo).map { variant in
                ContentID("theme.\(prefix).\(theme.rawValue).\(variant)")
            }
            let cooldown = ContentLibrary.defaultCooldown(for: movement)
            // Prefer cooldown-clear units, least-recently-served first;
            // deterministic order for ties (by key).
            let ranked = candidates.sorted { lhs, rhs in
                let lAge = lastServedDay(lhs.key) ?? Int.max
                let rAge = lastServedDay(rhs.key) ?? Int.max
                if lAge != rAge { return lAge > rAge }
                return lhs.key < rhs.key
            }
            for candidate in ranked {
                if (lastServedDay(candidate.key) ?? Int.max) > cooldown {
                    return candidate
                }
            }
            // All hot (small-library edge): least-recent wins anyway — rare,
            // deliberate repetition instead of a broken promise.
            return ranked.first ?? candidates[0]
        }

        // Titles share the discover pool namespace in copy ("theme.title.<t>.<n>").
        return ContentBundle(
            title: pick(.discover, prefixOverride: "title", modulo: 3),
            discover: pick(.discover, modulo: 3),
            reflect: pick(.reflect, modulo: 3),
            act: pick(.act, modulo: 3),
            returnPrompt: pick(.returnPrompt, modulo: 2)
        )
    }

    /// OUR DESIRE: freeze asymmetric assignments for both roles from the
    /// authored couple pool. Deterministic by day + theme.
    private static func coupleAssignments(
        theme: DayTheme,
        today: LocalDay,
        role: CoupleSpace?,
        history: [DailySessionRecord]
    ) -> [CoupleSpace: ContentID]? {
        // The authored pool has 7 pairs cycled across legacy days 1…21;
        // ongoing days continue cycling deterministically by calendar day.
        let poolSize = 7
        // Stable theme ordering index — never hashValue (process-random).
        let themeOrder: [DayTheme] = [.attention, .anticipation, .body, .novelty,
                                      .communication, .play, .closeness, .autonomy]
        let themeIndex = themeOrder.firstIndex(of: theme) ?? 0
        let seed = abs(today.days(since: LocalDay(storageKey: "2026-01-01"))) + themeIndex * 3
        let pairIndex = (seed % poolSize) + 1
        return [
            .partnerOne: ContentID("couple.asymmetric.pair.\(pairIndex).partnerOne"),
            .partnerTwo: ContentID("couple.asymmetric.pair.\(pairIndex).partnerTwo"),
        ]
    }
}
