import Foundation

// MARK: - JourneyPlanner
//
// The deterministic personalization engine. Pure function of
// (intention, profile, completedDays, checkIns) → what to live next.
//
// Bounded adaptation model:
//   * 21 days stay the conceptual arc; day numbers never run backwards.
//   * Anchor days (arrival / the turn / the keeper) are structural beats and
//     are never skipped — though they are reachable normally as `next`.
//   * Adaptation may only REORDER within a small look-ahead window, so the
//     journey stays coherent and explainable ("tomorrow, or the day after").
//   * Every signal has an explicit, readable effect. No black boxes.

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

    let dayNumber: Int
    let intensity: Intensity
    /// Top-scoring themes right now — selects authored copy variants.
    let emphasizedThemes: [DayTheme]
    /// Quiet pacing line derived from the latest evening honesty.
    let pacingNoteKey: String?
    /// True when the planner chose a DIFFERENT day than the plain sequence.
    let isAdapted: Bool
}

nonisolated enum JourneyPlanner {

    /// Look-ahead window: adaptation may pick any non-anchor day among the
    /// next three. Small enough to reason about, big enough to matter.
    static let lookAhead = 3

    static func recommend(
        intention: DesireIntention,
        profile: DesireProfile?,
        completedDays: [Int],
        checkIns: [CheckIn]
    ) -> DayRecommendation? {
        let shape = JourneyShape.shape(for: intention)
        guard !completedDays.contains(JourneyCatalog.totalDays) else { return nil }

        let nextBase = min(JourneyCatalog.totalDays, (completedDays.max() ?? 0) + 1)
        let intensity = self.intensity(from: checkIns)

        // Candidates: next…next+lookAhead, minus future anchors (they are
        // structural beats — we may arrive at them, never skip past them).
        let window = (nextBase...min(JourneyCatalog.totalDays, nextBase + lookAhead))
        var candidates = window.filter { $0 == nextBase || !shape.anchorDays.contains($0) }
        if candidates.isEmpty { candidates = [nextBase] }

        // No immediate thematic repeats: avoid serving the same theme twice
        // in a row when an alternative exists in the window.
        let previousTheme: DayTheme? = (nextBase > 1) ? shape.theme(for: nextBase - 1) : nil

        // Dominant dimensions drive affinity scoring.
        let dominant = profile?.dominant ?? []

        func score(_ day: Int) -> Double {
            let theme = shape.theme(for: day)
            var s = 0.0
            for dimension in dominant {
                s += ThemeAffinity.weight(dimension: dimension, theme: theme)
            }
            // A day matching the user's current emphasis is worth more even
            // without a dominant-dimension pull.
            if !dominant.isEmpty, dominant.contains(where: { ThemeAffinity.weight(dimension: $0, theme: theme) > 0 }) {
                s += 1
            }

            switch intensity {
            case .reduced:
                // Ground before challenging: attention/body rise, novelty/
                // charged themes wait.
                if theme == .attention || theme == .body { s += 2 }
                if theme == .novelty || theme == .play { s -= 1.5 }
            case .raised:
                if theme == .anticipation || theme == .novelty || theme == .play { s += 2 }
            case .steady:
                break
            }

            if let previousTheme, theme == previousTheme, candidates.count > 1 {
                s -= 3   // never the exact same flavor two days running if avoidable
            }
            return s
        }

        // Deterministic choice: highest score wins; ties break to the
        // earliest day.
        let ranked = candidates.sorted {
            let l = score($0), r = score($1)
            if l != r { return l > r }
            return $0 < $1
        }
        let chosen = ranked[0]

        // Emphasis: the two highest-affinity themes across the whole arc,
        // given the current dominance and intensity — used for copy variants.
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
            themeScores.append((theme, s))
        }
        let emphasized = themeScores
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.rawValue < rhs.0.rawValue
            }
            .prefix(2)
            .map(\.0)

        // Pacing line: unchanged contract from the check-in adapter.
        let pacingNoteKey = checkIns.last.flatMap { checkIn in
            CheckInAdapter.adjust(
                after: checkIn.response,
                dayNumber: checkIn.dayNumber,
                dominant: dominant
            ).pacingNoteKey
        }

        return DayRecommendation(
            dayNumber: chosen,
            intensity: intensity,
            emphasizedThemes: emphasized,
            pacingNoteKey: pacingNoteKey,
            isAdapted: chosen != nextBase
        )
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
