import Foundation

// MARK: - Journey content model
//
// A day = Discover (one idea) + Reflect (one prompt) + Act (one experiment).
// The evening Return is generated from the day's act. Content is authored in
// the String Catalog; this file only maps structure to keys.

nonisolated struct JourneyDay: Identifiable, Hashable, Sendable {
    let number: Int          // 1…21
    let week: Int            // 1…3
    let theme: DayTheme
    let discoverKey: String
    let reflectKey: String
    let actKey: String

    var titleKey: String { "day.\(number).title" }
    var returnPromptKey: String { "day.\(number).return" }
    var id: Int { number }
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

    private static let discoverSeeds: [String] = [
        "Desire often begins as attention. Before wanting more, notice what you already feel when the house goes quiet.",
        "The body keeps its own schedule. Ease — not effort — is usually the door desire walks through.",
        "Anticipation is a sense of its own. A hint today can do the work of an hour tomorrow.",
        "Attention is not a given; it is a practice. What you look at softly tends to warm.",
        "Looking forward and arriving are different pleasures. Give the first one room and the second softens.",
        "Desire listens for safety. It asks: can I want something here without being asked for anything back?",
        "Words draw maps. One honest sentence about what you miss can redraw the whole territory.",
        "Play is seriousness with its shoes off. Curiosity counts as intimacy even when it ends in laughter.",
        "Closeness compounds quietly — small daily warmth outperforms grand occasional gestures.",
        "Wanting needs elbow room. Autonomy is not distance; it is the space where choice still lives.",
        "Familiarity hides things in plain sight. Looking again — slowly — can make the known feel new.",
        "Pressure is the opposite of appetite. Removing expectation is itself a kind of invitation.",
        "Novelty right-sized is a doorway, not a leap: one new place, one new hour, one new question.",
        "Being wanted begins with being seen. Let yourself be witnessed in something small and true.",
        "Rituals hold tension beautifully. The same candle, the same song — repetition can charge a moment.",
        "Rest is part of desire. Tired bodies defend themselves with numbness; give yours permission first.",
        "Curiosity about your own responses is the most durable kind. You are allowed to be a mystery to yourself.",
        "Affection without agenda rebuilds trust in touch — a hand on a shoulder that wants nothing.",
        "Distance and closeness take turns. Naming which one you are in dissolves half the confusion.",
        "The last stretch belongs to anticipation: carry one small plan into tomorrow like a lit match cupped from wind.",
        "What you tended these three weeks is not a finish line. It is a hearth — it stays warm if you keep choosing it.",
    ]

    private static let reflectSeeds: [String] = [
        "When today went quiet for a moment, where did your attention go?",
        "Where in your body do you notice ease — even a little? What is near it?",
        "If desire arrived tonight like weather, what would the forecast say — honestly?",
        "What did you look at longer than you needed to today? What made you stay?",
        "What are you looking forward to that hasn't happened yet? Sit with it for a breath.",
        "What would make the next hour feel safe enough to want something in it?",
        "Finish this sentence without editing: \"What I miss is…\"",
        "When was the last time something felt playful between you — or inside you? Recall its texture.",
        "Name one tiny warmth from this week nobody else would have noticed.",
        "Where in your life do you currently have no room to choose? How does it feel in the body?",
        "Look at something familiar as if for the first time. What did you never notice?",
        "If no one expected anything of you tonight, what would you reach for first?",
        "Which small departure from routine could you make tomorrow without asking anyone's permission?",
        "Recall a moment you felt truly seen. Who witnessed you, and what exactly did they see?",
        "What repeated place or gesture could become charged again if you let it?",
        "What does tiredness talk you out of wanting? Write its exact words.",
        "Ask yourself a question you don't know the answer to. Keep it company for a minute.",
        "Think of affection that asked nothing of you. How did it change the rest of the day?",
        "Are you in a season of distance or of closeness right now? Name it without judging it.",
        "What is one thing worth looking forward to tomorrow? Make it specific enough to smell.",
        "After three weeks: what do you want to keep? Choose one thing and claim it in writing.",
    ]

    private static let actSeeds: [String] = [
        "Tonight, sit for two unhurried minutes with the lights low and simply notice what you feel — nothing to fix.",
        "Take a slower shower or bath than usual. Treat your own skin as familiar terrain worth revisiting.",
        "Plant one seed of anticipation: mention, lightly, that you have something small in mind for later this week.",
        "Once today, follow your attention on purpose — watch light move, listen to one full song, look slowly.",
        "Send a single line to someone safe: \"I've been thinking about Thursday.\" Nothing more needed.",
        "Before sleep, name three conditions that would make you feel safe enough to want. Just name them.",
        "Write one honest sentence about what you miss — and keep it somewhere only you will find it.",
        "Do one deliberately playful thing today: an absurd comment, a silly walk past a mirror, a game you win alone.",
        "Leave one small warmth for someone — or for future-you: a note, a folded shirt, a favorite mug set out.",
        "Cancel or shorten one obligation today. Feel the room it leaves behind.",
        "Choose one familiar object and give it five minutes of slow attention. Let it become new.",
        "Tonight, remove all expectations from one hour. Whatever happens — or doesn't — is the point.",
        "Change one detail of your usual: a different route, cup, playlist, or lamp. Notice how attention follows.",
        "Let someone catch you mid-delight today — humming, dancing, absorbed. Don't apologize for it.",
        "Recreate one ritual from early days — the same song, the same seat. Let memory do the charging.",
        "Go to bed thirty minutes earlier than justified. Desire negotiates with exhaustion; win that deal once.",
        "Follow one genuine question about yourself today — ask it out loud in your head and let it stay open.",
        "Give three no-agenda touches today: a hand on a shoulder, a brush of arms, fingers through hair — yours or theirs.",
        "Say aloud — to them or just to yourself — whether this week feels like distance or closeness.",
        "Whisper-plan tomorrow's smallest pleasure: the coffee, the light, the ten quiet minutes. Then protect it.",
        "Choose the one practice from these weeks you'll keep. Do it once more today — deliberately, as a keeper.",
    ]

    private static let returnSeeds: [String] = [
        "Did anything soften when you paid attention?",
        "Did your body tell you anything today?",
        "Is there anything you're quietly looking forward to now?",
        "Did you notice where your attention wanted to go?",
        "Did the waiting itself feel different today?",
        "Did it feel safer to want something today?",
        "Was it hard to keep the sentence honest? That's information too.",
        "Did anything make you smile at yourself today?",
        "Did you manage to leave — or find — one small warmth?",
        "Did saying no (to something small) leave any room behind?",
        "Did the familiar look even slightly new?",
        "What was it like to owe the hour nothing?",
        "Did one changed detail change your attention?",
        "Did being witnessed feel risky, warm, or both?",
        "Did the old song/place/seat hold any charge?",
        "Did rest arrive? Did anything wake up after it?",
        "Did the open question keep you company?",
        "Did touch without agenda land differently?",
        "Can you name which season you're in yet?",
        "Is tomorrow's small pleasure already glowing a little?",
        "Which keeper will you carry beyond these three weeks?",
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
                    theme: themesByDay[index],
                    discoverKey: "day.\(number).discover",
                    reflectKey: "day.\(number).reflect",
                    actKey: "day.\(number).act"
                )
            )
        }
        return built
    }

    /// Seeds exposed for the localization generator tooling.
    static let seeds: (discover: [String], reflect: [String], act: [String], returns: [String]) =
        (discoverSeeds, reflectSeeds, actSeeds, returnSeeds)
}
