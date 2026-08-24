import Foundation

// MARK: - ThemeSignals
//
// Lightweight, explainable learned signals per theme. This is the EVOLVING
// understanding that sits on top of the immutable onboarding profile:
// the profile is the starting prior; signals are slow-moving evidence.
//
// Rules:
//   * Bounded: resonance ∈ [-3, +3]; one check-in can never dominate.
//   * Projection: signals are rebuilt from sessionHistory — each session
//     contributes at most once via its final stored state.
//   * Low-resonance decays when positive evidence arrives (re-exposure),
//     so early cold streaks fade instead of haunting forever.
//   * Never shown to users as numbers. Internal scoring only.

nonisolated struct ThemeSignal: Equatable, Sendable, Codable {
    var exposureCount: Int = 0
    var positiveResonance: Double = 0     // noticedSomething/feltDifferent/wantMore
    var lowResonance: Double = 0          // nothingChanged
    var lastServedKey: String?            // LocalDay key (description) of most recent exposure
}

nonisolated struct LearnedSignals: Equatable, Sendable, Codable {
    var themes: [DayTheme: ThemeSignal] = [:]
    /// Rolling window of exact content IDs served, newest last.
    var recentContentKeys: [String] = []
    /// How many daily sessions have been lived (all-time). Free-gate input.
    var completedSessionCount: Int = 0

    static let empty = LearnedSignals()
}

// MARK: - Signal updates

nonisolated enum SignalUpdater {

    /// How much one response moves a theme's resonance. Deliberately small:
    /// no single evening may distort months of personalization.
    private static let weights: [CheckInResponse: Double] = [
        .nothingChanged: -0.5,
        .noticedSomething: 0.25,
        .feltDifferent: 0.75,
        .wantMore: 1.0,
    ]

    /// Records a day's exposure + its Return result into the signals.
    /// Pure function; bounded output.
    static func apply(
        _ record: DailySessionRecord,
        to signals: inout LearnedSignals,
        today: LocalDay
    ) {
        var signal = signals.themes[record.theme] ?? ThemeSignal()
        signal.exposureCount += 1
        signal.lastServedKey = record.day.description

        if let response = record.checkInResponse {
            let delta = weights[response] ?? 0
            if delta >= 0 {
                signal.positiveResonance = clamp(signal.positiveResonance + delta)
                // Low resonance decays — an early cold streak shouldn't haunt.
                signal.lowResonance = max(-3, signal.lowResonance * 0.8)
            } else {
                signal.lowResonance = clamp(signal.lowResonance + delta)
                signal.positiveResonance = max(0, signal.positiveResonance * 0.9)
            }
        }
        signals.themes[record.theme] = signal

        // Exact-content recency ring (bounded to keep state and scoring sane).
        for key in record.servedIDs where !signals.recentContentKeys.contains(key) {
            signals.recentContentKeys.append(key)
        }
        if signals.recentContentKeys.count > 120 {
            signals.recentContentKeys.removeFirst(signals.recentContentKeys.count - 120)
        }

        signals.completedSessionCount += 1
    }

    /// Net resonance for a theme in [-3 … +3]. Positive = this theme has been
    /// landing lately; negative = repeatedly flat.
    static func resonance(for theme: DayTheme, in signals: LearnedSignals) -> Double {
        guard let s = signals.themes[theme] else { return 0 }
        return clamp(s.positiveResonance + s.lowResonance)
    }

    private static func clamp(_ value: Double) -> Double {
        max(-3, min(3, value))
    }
}

// MARK: - History projection (source of truth)
//
// LearnedSignals is a deterministic CACHE of sessionHistory — never an
// independently accumulated log. Rebuilding from history is idempotent:
// each session contributes AT MOST ONCE using its FINAL stored state, so
// changing a Return answer ten times yields exactly the same signals as
// recording the final answer once.

nonisolated enum SignalProjector {

    nonisolated static func rebuild(from history: [DailySessionRecord]) -> LearnedSignals {
        var signals = LearnedSignals.empty

        // Chronological by canonical day key; stable for equal keys.
        let ordered = history.sorted { lhs, rhs in
            if lhs.day.storageKey != rhs.day.storageKey {
                return lhs.day.storageKey < rhs.day.storageKey
            }
            return lhs.id < rhs.id
        }

        // Collapse to the FINAL stored state per session id, applied once.
        let latestBySession: [String: DailySessionRecord] = {
            var latest: [String: DailySessionRecord] = [:]
            for record in ordered {
                latest[record.id] = record   // later entries overwrite earlier ones
            }
            return latest
        }()

        for record in latestBySession.values.sorted(by: { $0.id < $1.id }) {
            SignalUpdater.apply(record, to: &signals, today: record.day)
        }

        signals.completedSessionCount = latestBySession.values.filter {
            $0.completedMovements.contains(.act)
        }.count
        return signals
    }
}
