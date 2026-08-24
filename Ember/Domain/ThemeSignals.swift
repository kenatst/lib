import Foundation

// MARK: - ThemeSignals
//
// Lightweight, explainable learned signals per theme. This is the EVOLVING
// understanding that sits on top of the immutable onboarding profile:
// the profile is the starting prior; signals are slow-moving evidence.
//
// Rules:
//   * Bounded: resonance ∈ [-3, +3]; one check-in can never dominate.
//   * Decaying: old evidence fades so months-old misses stop mattering.
//   * Never shown to users as numbers. Internal scoring only.

nonisolated struct ThemeSignal: Equatable, Sendable, Codable {
    var exposureCount: Int = 0
    var positiveResonance: Double = 0     // noticedSomething/feltDifferent/wantMore
    var lowResonance: Double = 0          // nothingChanged
    var lastServedKey: String?            // LocalDay.storageKey of most recent exposure
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
        signal.lastServedKey = record.day.storageKey

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
