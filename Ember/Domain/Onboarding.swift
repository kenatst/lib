import Foundation

// MARK: - Onboarding questionnaire
//
// A short, branching, emotionally-intelligent intake. Questions are chosen
// per journey; every answer feeds the Desire Profile. No right answers,
// no scores shown to the user.

nonisolated enum Onboarding {

    struct Question: Hashable, Sendable {
        let id: QuestionID
        /// Localization key of the question text.
        let textKey: String
        let options: [Option]

        struct Option: Hashable, Sendable {
            let id: OptionID
            let textKey: String
            let dimension: Dimension
            let score: Int
        }
    }

    nonisolated enum QuestionID: String, CaseIterable, Codable, Sendable {
        case duration
        case stress
        case myState
        case mySelfConnection
        case myPressure
        case theirConnection
        case theirVoice
        case theirSeen
        case ourRhythm
        case ourTouch
        case ourCuriosity
    }

    nonisolated enum OptionID: String, Codable, Sendable {
        // duration
        case weeks, months, aYearOrMore, creptUp
        // stress
        case stressLight, stressSome, stressHeavy, stressSwings
        // my
        case quiet, flicker, blockedBySomething, longingWithoutShape
        case atEaseRecently, atEasePassing, atEaseDistant, rarelyNotice
        case pressureCuriosity, pressureGuilt, pressurePressure, pressureHope
        // their
        case warmUnderneath, fadedFromBefore, strained, mixedDays
        case voiceEasy, voiceHard, voiceAvoided, voiceOneWay
        case stillNoticed, seenFaded, feelInvisible, seenLoaded
        // our
        case lovingRoutine, logisticsAndTiredness, parallelLives, closenessWaves
        case touchAlive, touchRare, touchFunctional, touchCharged
        case curiosityStrong, curiosityDormant, curiosityBuried, curiosityRisky
    }

    static func questions(for intention: DesireIntention) -> [Question] {
        var qs: [Question] = [duration]
        switch intention {
        case .myDesire:
            qs += [stress, myState, mySelfConnection, myPressure]
        case .theirDesire:
            qs += [theirConnection, theirSeen, theirVoice]
        case .ourDesire:
            qs += [ourRhythm, ourTouch, ourCuriosity]
        }
        return qs
    }

    // MARK: Shared questions

    static let duration = Question(
        id: .duration,
        textKey: "q.duration.text",
        options: [
            .init(id: .weeks, textKey: "q.duration.weeks", dimension: .anticipation, score: 1),
            .init(id: .months, textKey: "q.duration.months", dimension: .novelty, score: 0),
            .init(id: .aYearOrMore, textKey: "q.duration.long", dimension: .anticipation, score: -1),
            .init(id: .creptUp, textKey: "q.duration.unsure", dimension: .selfConnection, score: -1),
        ]
    )

    static let stress = Question(
        id: .stress,
        textKey: "q.stress.text",
        options: [
            .init(id: .stressLight, textKey: "q.stress.light", dimension: .emotionalSafety, score: 2),
            .init(id: .stressSome, textKey: "q.stress.some", dimension: .emotionalSafety, score: 0),
            .init(id: .stressHeavy, textKey: "q.stress.heavy", dimension: .emotionalSafety, score: -2),
            .init(id: .stressSwings, textKey: "q.stress.swings", dimension: .emotionalSafety, score: -1),
        ]
    )

    // MARK: My Desire

    static let myState = Question(
        id: .myState,
        textKey: "q.my.state.text",
        options: [
            .init(id: .quiet, textKey: "q.my.state.quiet", dimension: .selfConnection, score: -2),
            .init(id: .flicker, textKey: "q.my.state.flicker", dimension: .anticipation, score: 1),
            .init(id: .blockedBySomething, textKey: "q.my.state.blocked", dimension: .autonomy, score: -2),
            .init(id: .longingWithoutShape, textKey: "q.my.state.longing", dimension: .anticipation, score: 2),
        ]
    )

    static let mySelfConnection = Question(
        id: .mySelfConnection,
        textKey: "q.my.selfconnection.text",
        options: [
            .init(id: .atEaseRecently, textKey: "q.my.selfconnection.recent", dimension: .selfConnection, score: 2),
            .init(id: .atEasePassing, textKey: "q.my.selfconnection.passing", dimension: .selfConnection, score: 0),
            .init(id: .atEaseDistant, textKey: "q.my.selfconnection.distant", dimension: .selfConnection, score: -2),
            .init(id: .rarelyNotice, textKey: "q.my.selfconnection.unsure", dimension: .selfConnection, score: -2),
        ]
    )

    static let myPressure = Question(
        id: .myPressure,
        textKey: "q.my.pressure.text",
        options: [
            .init(id: .pressureCuriosity, textKey: "q.my.pressure.curiosity", dimension: .playfulness, score: 2),
            .init(id: .pressureGuilt, textKey: "q.my.pressure.guilt", dimension: .autonomy, score: -2),
            .init(id: .pressurePressure, textKey: "q.my.pressure.pressure", dimension: .autonomy, score: -3),
            .init(id: .pressureHope, textKey: "q.my.pressure.hope", dimension: .confidence, score: 1),
        ]
    )

    // MARK: Their Desire

    static let theirConnection = Question(
        id: .theirConnection,
        textKey: "q.their.connection.text",
        options: [
            .init(id: .warmUnderneath, textKey: "q.their.connection.warm", dimension: .connection, score: 2),
            .init(id: .fadedFromBefore, textKey: "q.their.connection.faded", dimension: .connection, score: -1),
            .init(id: .strained, textKey: "q.their.connection.strained", dimension: .emotionalSafety, score: -2),
            .init(id: .mixedDays, textKey: "q.their.connection.mixed", dimension: .connection, score: 0),
        ]
    )

    static let theirVoice = Question(
        id: .theirVoice,
        textKey: "q.their.voice.text",
        options: [
            .init(id: .voiceEasy, textKey: "q.their.voice.easy", dimension: .communication, score: 2),
            .init(id: .voiceHard, textKey: "q.their.voice.hard", dimension: .communication, score: 0),
            .init(id: .voiceAvoided, textKey: "q.their.voice.avoided", dimension: .communication, score: -2),
            .init(id: .voiceOneWay, textKey: "q.their.voice.oneWay", dimension: .communication, score: -2),
        ]
    )

    static let theirSeen = Question(
        id: .theirSeen,
        textKey: "q.their.seen.text",
        options: [
            .init(id: .stillNoticed, textKey: "q.their.seen.noted", dimension: .confidence, score: 2),
            .init(id: .seenFaded, textKey: "q.their.seen.fade", dimension: .confidence, score: 0),
            .init(id: .feelInvisible, textKey: "q.their.seen.invisible", dimension: .confidence, score: -2),
            .init(id: .seenLoaded, textKey: "q.their.seen.loaded", dimension: .communication, score: -1),
        ]
    )

    // MARK: Our Desire

    static let ourRhythm = Question(
        id: .ourRhythm,
        textKey: "q.our.rhythm.text",
        options: [
            .init(id: .lovingRoutine, textKey: "q.our.rhythm.routine", dimension: .connection, score: 1),
            .init(id: .logisticsAndTiredness, textKey: "q.our.rhythm.logistics", dimension: .novelty, score: -2),
            .init(id: .parallelLives, textKey: "q.our.rhythm.parallel", dimension: .connection, score: -2),
            .init(id: .closenessWaves, textKey: "q.our.rhythm.waves", dimension: .anticipation, score: 1),
        ]
    )

    static let ourTouch = Question(
        id: .ourTouch,
        textKey: "q.our.touch.text",
        options: [
            .init(id: .touchAlive, textKey: "q.our.touch.alive", dimension: .playfulness, score: 2),
            .init(id: .touchRare, textKey: "q.our.touch.rare", dimension: .playfulness, score: -1),
            .init(id: .touchFunctional, textKey: "q.our.touch.functional", dimension: .playfulness, score: -2),
            .init(id: .touchCharged, textKey: "q.our.touch.charged", dimension: .emotionalSafety, score: -2),
        ]
    )

    static let ourCuriosity = Question(
        id: .ourCuriosity,
        textKey: "q.our.curiosity.text",
        options: [
            .init(id: .curiosityStrong, textKey: "q.our.curiosity.strong", dimension: .playfulness, score: 2),
            .init(id: .curiosityDormant, textKey: "q.our.curiosity.dormant", dimension: .playfulness, score: 0),
            .init(id: .curiosityBuried, textKey: "q.our.curiosity.buried", dimension: .novelty, score: -2),
            .init(id: .curiosityRisky, textKey: "q.our.curiosity.risky", dimension: .emotionalSafety, score: -2),
        ]
    )
}

// MARK: - Answers model

extension Onboarding {

    nonisolated struct Answer: Hashable, Codable, Sendable {
        let questionID: QuestionID
        let optionID: OptionID
    }

    /// Ordered answers keyed by question — one per asked question.
    nonisolated struct Responses: Equatable, Codable, Sendable {
        private(set) var answers: [QuestionID: Answer] = [:]
        private(set) var order: [QuestionID] = []

        mutating func record(_ answer: Answer) {
            if answers[answer.questionID] == nil {
                order.append(answer.questionID)
            }
            answers[answer.questionID] = answer
        }

        var count: Int { order.count }

        func option(for question: QuestionID) -> Onboarding.Question.Option? {
            guard let answer = answers[question] else { return nil }
            return Self.lookup(question: question, option: answer.optionID)
        }

        /// Reconstructs an Option from its IDs (pure lookup).
        static func lookup(question: QuestionID, option: OptionID) -> Onboarding.Question.Option? {
            for intention in DesireIntention.allCases {
                for q in Onboarding.questions(for: intention) where q.id == question {
                    return q.options.first { $0.id == option }
                }
            }
            return nil
        }
    }
}
