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

nonisolated struct CheckIn: Equatable, Sendable, Identifiable {
    /// The day this check-in closes (legacy course number; still the unique
    /// key for pre-engine data).
    let dayNumber: Int
    let response: CheckInResponse
    let date: Date
    /// The frozen session this Return belongs to (ongoing engine). nil for
    /// legacy/migrated entries. When present, sessionID is the uniqueness key.
    var sessionID: String?

    var id: String { sessionID ?? "legacy.\(dayNumber)" }

    init(dayNumber: Int, response: CheckInResponse, date: Date, sessionID: String? = nil) {
        self.dayNumber = dayNumber
        self.response = response
        self.date = date
        self.sessionID = sessionID
    }
}

extension CheckIn: Codable {
    private enum CodingKeys: String, CodingKey {
        case dayNumber, response, date, sessionID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.dayNumber = try c.decode(Int.self, forKey: .dayNumber)
        self.response = try c.decode(CheckInResponse.self, forKey: .response)
        self.date = try c.decode(Date.self, forKey: .date)
        // Legacy files have no sessionID — decode as nil, never fail.
        self.sessionID = try? c.decodeIfPresent(String.self, forKey: .sessionID)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(dayNumber, forKey: .dayNumber)
        try c.encode(response, forKey: .response)
        try c.encode(date, forKey: .date)
        try c.encodeIfPresent(sessionID, forKey: .sessionID)
    }
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
