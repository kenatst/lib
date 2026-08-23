import Foundation

// MARK: - Journey differentiation
//
// The three intentions share the same underlying arc (Noticing → Kindling →
// Tending) and content primitives, but they are NOT the same 21 days with
// different labels. Each intention gets:
//   * its own theme sequence (ordering differs),
//   * its own anchor days (fixed structural beats — never reordered),
//   * its own flexible-day pool ordering (how the planner may adapt),
//   * journey-specific emphasis weights used by the planner's scoring.
//
// Anchors: day 1 (arrival), day 8 (the turn inward/outward), day 21 (the
// keeper). Everything else can move within bounded constraints.

nonisolated struct JourneyShape: Sendable {

    let intention: DesireIntention
    /// One theme per day, in this journey's order.
    let themesByDay: [DayTheme]
    /// Days whose position is fixed regardless of adaptation.
    let anchorDays: Set<Int>

    func theme(for number: Int) -> DayTheme {
        themesByDay[number - 1]
    }

    // MARK: The three shapes

    static let all: [DesireIntention: JourneyShape] = [
        .myDesire: myDesire,
        .theirDesire: theirDesire,
        .ourDesire: ourDesire,
    ]

    static func shape(for intention: DesireIntention) -> JourneyShape {
        all[intention] ?? myDesire
    }

    /// MY DESIRE — the return toward oneself.
    /// Leads with body awareness, permission and removal of pressure;
    /// novelty arrives late and gently; anticipation is reframed as
    /// self-anticipation before it ever points outward.
    private static let myDesire = JourneyShape(
        intention: .myDesire,
        themesByDay: [
            .attention, .body, .attention,            // week 1 — noticing self
            .autonomy, .body, .anticipation, .novelty, // week 2 — room, then spark
            .communication,                            //   (self-talk counts)
            .play, .body, .closeness, .anticipation,   // week 3 — keeping it
            .novelty, .autonomy,
            .play, .closeness, .attention,
            .autonomy, .anticipation, .body,
        ],
        anchorDays: [1, 8, 21]
    )

    /// THEIR DESIRE — the conditions around being wanted.
    /// Attention and communication carry the early weeks; confidence and
    /// presence build mid-journey; autonomy protects against performing.
    private static let theirDesire = JourneyShape(
        intention: .theirDesire,
        themesByDay: [
            .attention, .communication, .attention,     // week 1 — being seen
            .confidence, .anticipation, .communication, .novelty, // week 2 — presence
            .closeness,
            .play, .autonomy, .anticipation, .novelty,  // week 3 — charged again
            .communication, .confidence,
            .play, .closeness, .attention,
            .autonomy, .anticipation, .closeness,
        ],
        anchorDays: [1, 9, 21]
    )

    /// OUR DESIRE — two lines weaving while remaining distinct.
    /// Communication and small shared rituals early; play and novelty mid;
    /// independence deliberately re-entered late so closeness stays chosen.
    private static let ourDesire = JourneyShape(
        intention: .ourDesire,
        themesByDay: [
            .communication, .closeness, .attention,     // week 1 — us, plainly
            .novelty, .anticipation, .communication, .play, // week 2 — new together
            .closeness,
            .anticipation, .novelty, .play, .closeness, // week 3 — distinct, woven
            .autonomy, .attention,
            .play, .novelty, .communication,
            .autonomy, .anticipation, .closeness,
        ],
        anchorDays: [1, 10, 21]
    )
}

// MARK: - Dimension → theme affinity
//
// How strongly each profile dimension pulls a given theme when scoring
// candidate days. Deliberately explicit and readable — no black boxes.

nonisolated enum ThemeAffinity {

    static func weight(dimension: Dimension, theme: DayTheme) -> Double {
        switch (dimension, theme) {
        case (.anticipation, .anticipation): return 3
        case (.anticipation, .novelty): return 2
        case (.connection, .closeness): return 3
        case (.connection, .communication): return 2
        case (.novelty, .novelty): return 3
        case (.novelty, .play): return 2
        case (.autonomy, .autonomy): return 3
        case (.autonomy, .body): return 1
        case (.selfConnection, .body): return 3
        case (.selfConnection, .attention): return 2
        case (.confidence, .body): return 2
        case (.confidence, .attention): return 2
        case (.playfulness, .play): return 3
        case (.playfulness, .novelty): return 2
        case (.communication, .communication): return 3
        case (.communication, .closeness): return 2
        case (.emotionalSafety, .closeness): return 2
        case (.emotionalSafety, .body): return 2
        case (.emotionalSafety, .communication): return 1
        default: return 0
        }
    }
}
