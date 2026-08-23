import Foundation

// MARK: - Evening check-in
//
// The Return: a one-tap reflection that tunes later days. Responses are
// qualitative — never scored, never shown as streaks.

nonisolated enum CheckInResponse: String, Codable, CaseIterable, Sendable {
    case nothingChanged
    case noticedSomething
    case feltDifferent
    case wantMore

    var textKey: String { "return.\(rawValue)" }
}

nonisolated struct CheckIn: Codable, Equatable, Sendable, Identifiable {
    /// The day this check-in closes.
    let dayNumber: Int
    let response: CheckInResponse
    let date: Date

    var id: Int { dayNumber }
}

// MARK: - Adaptation engine

nonisolated enum CheckInAdapter {

    nonisolated struct Adjustment: Equatable, Sendable {
        /// Extra discover emphasis for these themes in upcoming days.
        let emphasizeThemes: [DayTheme]
        /// Suggested pacing nudge (shown subtly on home, never as pressure).
        let pacingNoteKey: String?
    }

    /// Derives how the journey should lean after a check-in.
    /// Pure function of (response, current day, dominant dimensions).
    static func adjust(
        after response: CheckInResponse,
        dayNumber: Int,
        dominant: [Dimension]
    ) -> Adjustment {
        switch response {
        case .nothingChanged:
            // Slow down: re-run nearby attention/body themes with less novelty.
            return Adjustment(
                emphasizeThemes: [.attention, .body],
                pacingNoteKey: "pacing.gentle"
            )
        case .noticedSomething:
            // Keep the thread: emphasize the day's own theme next.
            return Adjustment(
                emphasizeThemes: [],
                pacingNoteKey: "pacing.thread"
            )
        case .feltDifferent:
            // Lean further into what worked: the dominant dimensions' themes.
            let themeMap: [Dimension: DayTheme] = [
                .anticipation: .anticipation,
                .connection: .closeness,
                .novelty: .novelty,
                .autonomy: .autonomy,
                .selfConnection: .body,
                .confidence: .body,
                .playfulness: .play,
                .communication: .communication,
                .emotionalSafety: .closeness,
            ]
            let themes = dominant.compactMap { themeMap[$0] }
            return Adjustment(
                emphasizeThemes: Array(Set(themes)).sorted { $0.rawValue < $1.rawValue },
                pacingNoteKey: nil
            )
        case .wantMore:
            // Raise the dose slightly: anticipation + the journey's own arc.
            return Adjustment(
                emphasizeThemes: [.anticipation],
                pacingNoteKey: "pacing.dose"
            )
        }
    }
}
