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

    /// Deterministic epoch for ongoing-day arithmetic (couple rotation).
    nonisolated static let legacyEpoch = LocalDay.unchecked("2026-01-01")

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
        "\(day.description)#\(intention.rawValue)"
    }

    // MARK: Dose

    /// Today's dose comes from SESSION HISTORY — the most recent Return in
    /// real calendar chronology — never from legacy day-numbered CheckIns.
    ///
    /// Semantics:
    ///   * today's Return changes TOMORROW's dose (it isn't consulted for the
    ///     plan it belongs to — that plan was frozen before the answer),
    ///   * a missed Return is neutral: the last answered Return stands,
    ///   * skipped days add nothing, and legacy/duplicate CheckIns can't
    ///     distort ongoing planning because they aren't an input here.
    nonisolated static func intensity(from history: [DailySessionRecord]) -> Intensity {
        guard let latest = latestAnsweredRecord(in: history),
              let response = latest.checkInResponse else { return .steady }
        switch response {
        case .nothingChanged: return .gentle
        case .wantMore: return .deeper
        case .noticedSomething, .feltDifferent: return .steady
        }
    }

    /// The most recent session carrying a completed Return, by canonical day.
    nonisolated static func latestAnsweredRecord(
        in history: [DailySessionRecord]
    ) -> DailySessionRecord? {
        history
            .filter { $0.checkInResponse != nil }
            .max { lhs, rhs in
                if lhs.day.storageKey != rhs.day.storageKey {
                    return lhs.day.storageKey < rhs.day.storageKey
                }
                return lhs.id < rhs.id
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
    /// - Parameters:
    ///   - today: canonical local day (injectable for tests/simulations)
    ///   - plans: known frozen plans (persisted store)
    ///   - history: session records (persisted store) — dose + recency source
    ///   - signals: learned signals (persisted store; a projection of history)
    static func planForToday(
        today: LocalDay,
        intention: DesireIntention,
        profile: DesireProfile?,
        plans: [String: DailyPlan],
        history: [DailySessionRecord],
        signals: LearnedSignals,
        coupleRole: CoupleSpace?
    ) -> DailyPlan {
        let id = planID(day: today, intention: intention)
        if let existing = plans[id] {
            return existing                       // IDEMPOTENT — never re-recommend
        }

        // DOSE SOURCE OF TRUTH: session history. The legacy [CheckIn] array
        // no longer drives ongoing personalization.
        let intensity = self.intensity(from: history)
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

        // Recent themes get strong saturation penalties so the engine cannot
        // loop on one note: yesterday −3.5, two days ago −2.5, etc. This keeps
        // exact-content pools ahead of demand (a theme recurring every ≥3 days
        // gives its 6-unit pool 18 days of coverage).
        let recentSix = history.suffix(6).map(\.theme)
        var recencyPenalty: [DayTheme: Double] = [:]
        let penalties = [3.5, 2.8, 2.1, 1.5, 1.0, 0.6]
        for theme in Set(recentSix) {
            var penalty = 0.0
            for (distance, p) in penalties.enumerated() {
                if distance < recentSix.count,
                   recentSix[recentSix.count - 1 - distance] == theme {
                    penalty += p
                }
            }
            recencyPenalty[theme] = penalty
        }

        // Position within the shape's arc — the engine still walks the authored
        // rhythm as its base pulse, cycling forever after the seed 21 days.
        let seedPosition = seedPosition(forToday: today, history: history, shape: shape)

        // HARD NO-REPEAT RULE: neither of the two most recent sessions' themes
        // may be chosen. A daily guide that keeps repeating its headline idea
        // reads as broken; every other consideration yields to this. Two
        // (not one) because skipped days can otherwise make "yesterday" a
        // poor proxy for "recently".
        let recentThemes = Set(history.suffix(2).map(\.theme))

        var scores: [DayTheme: Double] = [:]
        for theme in DayTheme.allCases {
            if recentThemes.contains(theme) {
                scores[theme] = -1000
                continue
            }
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
            // Days AGO the unit was last served; nil if never.
            for record in history.reversed() where record.servedIDs.contains(key) {
                return today.days(since: record.day)
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
            // All soft windows hot (hot theme, finite pool): enforce a HARD
            // one-week minimum spacing per exact unit via LRU. With a 6-unit
            // pool this still guarantees ≥6-day gaps even under daily
            // recurrence; the 30-day goal resumes as soon as the theme cools.
            for candidate in ranked {
                if (lastServedDay(candidate.key) ?? Int.max) >= 7 {
                    return candidate
                }
            }
            // Degenerate (>6 consecutive days on one theme): least-recent.
            return ranked.first ?? candidates[0]
        }

        // Titles keep the original 3-variant pool; the rest grew to 6
        // (returns to 4) with Mission 004's library expansion.
        return ContentBundle(
            title: pick(.discover, prefixOverride: "title", modulo: 3),
            discover: pick(.discover, modulo: 6),
            reflect: pick(.reflect, modulo: 6),
            act: pick(.act, modulo: 6),
            returnPrompt: pick(.returnPrompt, modulo: 4)
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
        let seed = abs(today.days(since: legacyEpoch)) + themeIndex * 3
        let pairIndex = (seed % poolSize) + 1
        return [
            .partnerOne: ContentID("couple.asymmetric.pair.\(pairIndex).partnerOne"),
            .partnerTwo: ContentID("couple.asymmetric.pair.\(pairIndex).partnerTwo"),
        ]
    }
}
