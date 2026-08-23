import Foundation

// MARK: - JourneyPlanner
//
// The deterministic personalization engine.
//
// PROGRESSION MODEL (release invariant):
//   * The journey has 21 POSITIONS. The next position is
//     min(21, count of completed experiences + 1) — position advances by
//     exactly one per completion and NEVER skips, so every slot is served,
//     none repeats, and the arc always terminates after 21 completions.
//   * Adaptation never changes WHICH position comes next. It chooses which
//     THEME that position carries, drawn from the journey shape's upcoming
//     themes within a bounded look-ahead window (anchors stay in place; an
//     anchor theme can be pulled EARLIER, never pushed later). The swapped-
//     out themes are not lost — they flow back into later positions.
//
//   Invariants (exhaustively simulated in JourneyPlannerTests):
//     - exactly 21 unique experiences complete the journey
//     - no slot is skipped, none served twice
//     - adaptation stays bounded (≤ lookAhead positions ahead)
//     - anchors are respected
//     - output is deterministic for identical inputs

nonisolated struct DayRecommendation: Equatable, Sendable {

    /// How hard the journey is currently pushing.
    nonisolated enum Intensity: String, Equatable, Sendable {
        case reduced    // nothing changed → softer, grounding themes first
        case steady     // default
        case raised     // want more → slightly more anticipation/challenge

        var scoreBias: Double {
            switch self {
            case .reduced: -1
            case .steady: 0
            case .raised: 1
            }
        }
    }

    /// The progression position (1…21) — always one past the last completion.
    let dayNumber: Int
    let intensity: Intensity
    /// Top-scoring themes right now — selects authored copy variants.
    let emphasizedThemes: [DayTheme]
    /// Quiet pacing line derived from the latest evening honesty.
    let pacingNoteKey: String?
    /// True when this position's theme was reordered relative to the plain arc.
    let isAdapted: Bool
}

nonisolated struct ThemePlan: Equatable, Sendable {
    let theme: DayTheme
    let isAdapted: Bool
}

nonisolated enum JourneyPlanner {

    /// Look-ahead window: adaptation may pull a theme forward from up to
    /// this many positions ahead. Small enough to reason about.
    static let lookAhead = 3

    static func recommend(
        intention: DesireIntention,
        profile: DesireProfile?,
        completedDays: [Int],
        checkIns: [CheckIn]
    ) -> DayRecommendation? {
        // POSITION = the FIRST UNCOMPLETED SLOT. Not max()+1, not raw count:
        // immune to duplicated or gapped history by construction. It can
        // never re-serve a completed slot, always fills any hole first, and
        // guarantees exhaustion of all 21 experiences.
        let completed = Set(completedDays.filter { (1...JourneyCatalog.totalDays).contains($0) })
        guard completed.count < JourneyCatalog.totalDays else { return nil }
        var position = JourneyCatalog.totalDays
        for slot in 1...JourneyCatalog.totalDays where !completed.contains(slot) {
            position = slot
            break
        }

        let intensity = self.intensity(from: checkIns)

        let plan = planTheme(
            intention: intention,
            position: position,
            profile: profile,
            intensity: intensity
        )

        let dominant = profile?.dominant ?? []

        // Emphasis: the two highest-affinity themes across the whole arc,
        // given dominance, guard and intensity — used for copy variants.
        let guarded = profile?.readings.filter { $0.band == .guarded }.map(\.dimension) ?? []
        let emphasized = emphasizedThemes(dominant: dominant, guarded: guarded, intensity: intensity)

        // Pacing line: unchanged contract from the check-in adapter.
        let pacingNoteKey = checkIns.last.flatMap { checkIn in
            CheckInAdapter.adjust(
                after: checkIn.response,
                dayNumber: checkIn.dayNumber,
                dominant: dominant
            ).pacingNoteKey
        }

        return DayRecommendation(
            dayNumber: position,
            intensity: intensity,
            emphasizedThemes: emphasized,
            pacingNoteKey: pacingNoteKey,
            isAdapted: plan.isAdapted
        )
    }

    /// The day as it should be EXPERIENCED at `number`: the position's
    /// planned theme (possibly reordered within bounds), wrapped as a
    /// JourneyDay for the content resolvers.
    nonisolated static func plannedDay(
        number: Int,
        intention: DesireIntention,
        profile: DesireProfile?,
        checkIns: [CheckIn]
    ) -> JourneyDay? {
        guard let base = JourneyCatalog.day(number) else { return nil }
        let intensityValue = intensity(from: checkIns)
        let plan = planTheme(intention: intention, position: number, profile: profile, intensity: intensityValue)
        return JourneyDay(number: base.number, week: base.week, theme: plan.theme)
    }

    /// Decides which theme the given position carries. Pure.
    ///
    /// Candidates are the shape's themes at position…position+lookAhead.
    /// Anchors are immovable: they can be chosen now (arriving early is how
    /// an anchor keeps its place), but their theme cannot be deferred past
    /// its natural position. The best-scoring candidate theme is assigned to
    /// this position; the displaced theme returns to service later.
    nonisolated static func planTheme(
        intention: DesireIntention,
        position: Int,
        profile: DesireProfile?,
        intensity: DayRecommendation.Intensity
    ) -> ThemePlan {
        let shape = JourneyShape.shape(for: intention)
        let natural = shape.theme(for: position)

        // ANCHOR RULE (strict): an anchor position is immovable — its theme
        // is a structural beat and is always served exactly there.
        if shape.anchorDays.contains(position) {
            return ThemePlan(theme: natural, isAdapted: false)
        }

        // Candidate pool: themes of the next few positions (clamped to arc).
        // Anchor positions are excluded as SOURCES too: their themes may not
        // be pulled early, so the anchor beat always lands on its own day.
        let windowEnd = min(JourneyCatalog.totalDays, position + lookAhead)
        var selectablePositions = (position...windowEnd).filter { !shape.anchorDays.contains($0) }
        if selectablePositions.isEmpty { selectablePositions = [position] }

        let dominant = profile?.dominant ?? []
        let guarded = profile?.readings.filter { $0.band == .guarded }.map(\.dimension) ?? []

        func score(_ day: Int) -> Double {
            let theme = shape.theme(for: day)
            var s = 0.0
            for dimension in dominant {
                s += ThemeAffinity.weight(dimension: dimension, theme: theme)
            }
            if !dominant.isEmpty,
               dominant.contains(where: { ThemeAffinity.weight(dimension: $0, theme: theme) > 0 }) {
                s += 1
            }

            switch intensity {
            case .reduced:
                if theme == .attention || theme == .body { s += 2 }
                if theme == .novelty || theme == .play { s -= 1.5 }
            case .raised:
                if theme == .anticipation || theme == .novelty || theme == .play { s += 2 }
            case .steady:
                break
            }

            if !guarded.isEmpty {
                s += groundedAdjustment(theme)
                for dimension in guarded {
                    s += ThemeAffinity.weight(dimension: dimension, theme: theme)
                }
            }

            // Mild preference for the natural order when nothing pulls.
            s -= Double(day - position) * 0.25
            return s
        }

        // Deterministic: highest score wins, ties break to earliest position.
        let ranked = selectablePositions.sorted {
            let l = score($0), r = score($1)
            if l != r { return l > r }
            return $0 < $1
        }
        let chosenPosition = ranked[0]
        return ThemePlan(
            theme: shape.theme(for: chosenPosition),
            isAdapted: chosenPosition != position
        )
    }

    nonisolated static func groundedAdjustment(_ theme: DayTheme) -> Double {
        var adj = 0.0
        if theme == .novelty || theme == .play || theme == .anticipation { adj -= 2 }
        if theme == .closeness || theme == .body || theme == .attention { adj += 1 }
        return adj
    }

    nonisolated static func emphasizedThemes(
        dominant: [Dimension],
        guarded: [Dimension],
        intensity: DayRecommendation.Intensity
    ) -> [DayTheme] {
        var themeScores: [(DayTheme, Double)] = []
        for theme in [DayTheme.attention, .anticipation, .body, .novelty, .communication, .play, .closeness, .autonomy] {
            var s = 0.0
            for dimension in dominant {
                s += ThemeAffinity.weight(dimension: dimension, theme: theme)
            }
            switch intensity {
            case .reduced:
                if theme == .attention || theme == .body { s += 2 }
            case .raised:
                if theme == .anticipation || theme == .novelty || theme == .play { s += 2 }
            case .steady:
                break
            }
            if !guarded.isEmpty {
                s += groundedAdjustment(theme)
                for dimension in guarded {
                    s += ThemeAffinity.weight(dimension: dimension, theme: theme)
                }
            }
            themeScores.append((theme, s))
        }
        return themeScores
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.rawValue < rhs.0.rawValue
            }
            .prefix(2)
            .map(\.0)
    }

    /// Most recent evening honesty decides today's dose.
    static func intensity(from checkIns: [CheckIn]) -> DayRecommendation.Intensity {
        guard let last = checkIns.max(by: { $0.dayNumber < $1.dayNumber }) else { return .steady }
        switch last.response {
        case .nothingChanged: return .reduced
        case .wantMore: return .raised
        case .noticedSomething, .feltDifferent: return .steady
        }
    }
}
