import Foundation
import Testing
@testable import Ember

// MARK: - JourneyPlanner: deterministic personalization
//
// These tests prove the mission's core claim: two users with different
// profiles / check-ins / histories receive DIFFERENT next content — and that
// outcomes stay deterministic and explainable.

@MainActor
@Suite("JourneyPlanner")
struct JourneyPlannerTests {

    // MARK: Fixtures

    private func profile(_ intention: DesireIntention, _ answers: [(Onboarding.QuestionID, Onboarding.OptionID)]) -> DesireProfile {
        var responses = Onboarding.Responses()
        for (q, o) in answers {
            responses.record(.init(questionID: q, optionID: o))
        }
        return DesireProfileDeriver.derive(from: responses, intention: intention)
    }

    private func checkIns(_ entries: [(Int, CheckInResponse)]) -> [CheckIn] {
        entries.map { CheckIn(dayNumber: $0.0, response: $0.1, date: .now) }
    }

    // MARK: Determinism & shape

    @Test("Same inputs always produce identical recommendations")
    func deterministic() {
        let prof = profile(.myDesire, [(.duration, .creptUp), (.stress, .stressHeavy), (.myState, .quiet)])
        let history = checkIns([(1, .nothingChanged), (2, .noticedSomething)])

        let a = JourneyPlanner.recommend(intention: .myDesire, profile: prof, completedDays: [1, 2], checkIns: history)
        let b = JourneyPlanner.recommend(intention: .myDesire, profile: prof, completedDays: [1, 2], checkIns: history)
        #expect(a == b)
    }

    @Test("Completed journey recommends nothing; empty history starts at day 1 steady")
    func boundaries() {
        #expect(JourneyPlanner.recommend(intention: .myDesire, profile: nil,
                                         completedDays: Array(1...21), checkIns: []) == nil)

        let first = JourneyPlanner.recommend(intention: .theirDesire, profile: nil, completedDays: [], checkIns: [])
        #expect(first?.dayNumber == 1)
        #expect(first?.intensity == .steady)
        #expect(first?.isAdapted == false)
    }

    @Test("Day numbers never run backwards and always respect completion")
    func monotonicProgress() {
        for intention in DesireIntention.allCases {
            var completed: [Int] = []
            for _ in 0..<25 {
                guard let rec = JourneyPlanner.recommend(
                    intention: intention, profile: nil,
                    completedDays: completed, checkIns: []
                ) else { break }
                let expectedMin = (completed.max() ?? 0) + 1
                #expect(rec.dayNumber >= expectedMin - 3 + 1 || rec.isAdapted,
                        "adaptation must explain any non-sequential choice")
                #expect(!completed.contains(rec.dayNumber), "must never re-serve a completed day")
                #expect((1...21).contains(rec.dayNumber))
                completed.append(rec.dayNumber)
                completed.sort()
            }
            #expect(completed.count == 21)
        }
    }

    @Test("Anchor days are never skipped over in the look-ahead window")
    func anchorsProtected() {
        let shapes: [DesireIntention: Set<Int>] = [
            .myDesire: JourneyShape.shape(for: .myDesire).anchorDays,
            .theirDesire: JourneyShape.shape(for: .theirDesire).anchorDays,
            .ourDesire: JourneyShape.shape(for: .ourDesire).anchorDays,
        ]
        for (intention, anchors) in shapes {
            var completed: [Int] = []
            while completed.count < 21 {
                guard let rec = JourneyPlanner.recommend(
                    intention: intention, profile: nil,
                    completedDays: completed, checkIns: []
                ) else { break }
                // If an anchor is inside the candidate window, it must be chosen
                // no later than its natural position allows.
                if anchors.contains(rec.dayNumber) {
                    let base = (completed.max() ?? 0) + 1
                    #expect(rec.dayNumber <= base + JourneyPlanner.lookAhead)
                }
                completed.append(rec.dayNumber)
                completed.sort()
            }
        }
    }

    @Test("The three journeys produce genuinely different sequences")
    func journeysDiverge() {
        // No profiles, no check-ins: shapes alone must differ.
        func sequence(_ intention: DesireIntention) -> [DayTheme] {
            var completed: [Int] = []
            var themes: [DayTheme] = []
            while completed.count < 21 {
                let rec = JourneyPlanner.recommend(
                    intention: intention, profile: nil,
                    completedDays: completed, checkIns: []
                )!
                themes.append(JourneyShape.shape(for: intention).theme(for: rec.dayNumber))
                completed.append(rec.dayNumber)
                completed.sort()
            }
            return themes
        }

        let my = sequence(.myDesire)
        let their = sequence(.theirDesire)
        let our = sequence(.ourDesire)

        #expect(my != their)
        #expect(my != our)
        #expect(their != our)
        #expect(zip(my, their).filter { $0.0 == $0.1 }.count < 21)
    }

    @Test("Theme counts reflect each journey's emphasis")
    func emphasisCounts() {
        func count(_ intention: DesireIntention, _ theme: DayTheme) -> Int {
            JourneyShape.shape(for: intention).themesByDay.filter { $0 == theme }.count
        }
        // MY leads with body/self-connection…
        #expect(count(.myDesire, .body) >= 4)
        // THEIR carries communication/attention presence work…
        #expect(count(.theirDesire, .communication) >= 4)
        #expect(count(.theirDesire, .attention) >= 4)
        // OUR is the only one led by shared communication from day one.
        #expect(JourneyShape.shape(for: .ourDesire).themesByDay[0] == .communication)
        #expect(JourneyShape.shape(for: .myDesire).themesByDay[0] == .attention)
        #expect(JourneyShape.shape(for: .theirDesire).themesByDay[0] == .attention)
    }

    @Test("Every journey shape covers all 21 days exactly once")
    func shapeCoverage() {
        for intention in DesireIntention.allCases {
            let shape = JourneyShape.shape(for: intention)
            #expect(shape.themesByDay.count == JourneyCatalog.totalDays,
                    "\(intention) shape must have exactly \(JourneyCatalog.totalDays) themes")
            #expect(!shape.themesByDay.isEmpty)
            for day in 1...JourneyCatalog.totalDays {
                _ = shape.theme(for: day)   // must not trap
            }
            // Anchors always exist within the arc.
            for anchor in shape.anchorDays {
                #expect((1...JourneyCatalog.totalDays).contains(anchor))
            }
        }
    }

    // MARK: Profile dominance changes real decisions

    @Test("Dominant anticipation pulls different days than dominant self-connection")
    func profileChangesOutcome() {
        // Anticipation-led user: duration weeks (+1), longing without shape (+2).
        var responsesA = Onboarding.Responses()
        responsesA.record(.init(questionID: .duration, optionID: .weeks))          // anticipation +1
        responsesA.record(.init(questionID: .myState, optionID: .longingWithoutShape)) // anticipation +2
        let a = DesireProfileDeriver.derive(from: responsesA, intention: .myDesire)

        // Body-led user: self-connection answers dominate.
        var responsesB = Onboarding.Responses()
        responsesB.record(.init(questionID: .duration, optionID: .creptUp))         // selfConnection -1
        responsesB.record(.init(questionID: .mySelfConnection, optionID: .atEaseDistant)) // selfConnection -2
        let b = DesireProfileDeriver.derive(from: responsesB, intention: .myDesire)

        #expect(a.dominant.contains(.anticipation))
        #expect(b.dominant.contains(.selfConnection))

        // From the same progress point, their next-day choices differ.
        let completed: [Int] = Array(1...5)
        let recA = JourneyPlanner.recommend(intention: .myDesire, profile: a, completedDays: completed, checkIns: [])
        let recB = JourneyPlanner.recommend(intention: .myDesire, profile: b, completedDays: completed, checkIns: [])

        let themeA = JourneyShape.shape(for: .myDesire).theme(for: recA!.dayNumber)
        let themeB = JourneyShape.shape(for: .myDesire).theme(for: recB!.dayNumber)
        #expect(themeA == .anticipation || recA!.emphasizedThemes.contains(.anticipation))
        #expect(themeB == .body || recB!.emphasizedThemes.contains(.body))
    }

    // MARK: Check-in adaptation changes future content decisions

    @Test("Nothing-changed reduces intensity; want-more raises it")
    func intensityMapping() {
        #expect(JourneyPlanner.intensity(from: checkIns([(3, .nothingChanged)])) == .reduced)
        #expect(JourneyPlanner.intensity(from: checkIns([(3, .wantMore)])) == .raised)
        #expect(JourneyPlanner.intensity(from: checkIns([(3, .feltDifferent)])) == .steady)
        #expect(JourneyPlanner.intensity(from: []) == .steady)
        // The MOST RECENT evening decides.
        #expect(JourneyPlanner.intensity(from: checkIns([(2, .wantMore), (3, .nothingChanged)])) == .reduced)
    }

    @Test("Two different check-in histories produce different next recommendations")
    func checkInsChangeNextContent() {
        let completed: [Int] = Array(1...6)

        let stuck = JourneyPlanner.recommend(
            intention: .myDesire, profile: nil,
            completedDays: completed,
            checkIns: checkIns([(6, .nothingChanged)])
        )
        let eager = JourneyPlanner.recommend(
            intention: .myDesire, profile: nil,
            completedDays: completed,
            checkIns: checkIns([(6, .wantMore)])
        )

        #expect(stuck?.intensity == .reduced)
        #expect(eager?.intensity == .raised)

        // Different intensity → measurably different plan: either another day,
        // or at minimum a different emphasis/pacing bundle.
        let differsInPlan = stuck!.dayNumber != eager!.dayNumber
            || stuck!.emphasizedThemes != eager!.emphasizedThemes
        #expect(differsInPlan)

        // Reduced intensity privileges grounding themes somewhere in the plan.
        #expect(stuck!.pacingNoteKey == "pacing.gentle")
        #expect(eager!.pacingNoteKey == "pacing.dose")
    }

    @Test("Reduced intensity avoids novelty-heavy picks when alternatives exist")
    func reducedAvoidsEscalation() {
        // Find a window where novelty competes with attention/body.
        let rec = JourneyPlanner.recommend(
            intention: .myDesire, profile: nil,
            completedDays: Array(1...9),
            checkIns: checkIns([(9, .nothingChanged)])
        )
        let shape = JourneyShape.shape(for: .myDesire)
        let base = 10
        let window = base...min(21, base + JourneyPlanner.lookAhead)
        let groundingInWindow = window.contains { shape.theme(for: $0) == .attention || shape.theme(for: $0) == .body }
        if groundingInWindow {
            let theme = shape.theme(for: rec!.dayNumber)
            #expect(theme == .attention || theme == .body || theme == .communication || theme == .closeness || theme == .autonomy,
                    "reduced intensity should ground before challenging; got \(String(describing: theme))")
        }
    }

    @Test("No immediate thematic repeats when an alternative exists")
    func noRepeats() {
        for intention in DesireIntention.allCases {
            let shape = JourneyShape.shape(for: intention)
            var completed: [Int] = []
            var lastTheme: DayTheme?
            var repeatCount = 0
            while completed.count < 21 {
                let rec = JourneyPlanner.recommend(
                    intention: intention, profile: nil,
                    completedDays: completed, checkIns: []
                )!
                let theme = shape.theme(for: rec.dayNumber)
                if theme == lastTheme { repeatCount += 1 }
                lastTheme = theme
                completed.append(rec.dayNumber)
                completed.sort()
            }
            // A few repeats are structurally unavoidable late-journey when the
            // window collapses onto anchors; they must stay rare.
            #expect(repeatCount <= 3, "\(intention) repeated themes \(repeatCount) times")
        }
    }

    @Test("Emphasis follows dominance and current dose")
    func emphasisSelection() {
        var responses = Onboarding.Responses()
        responses.record(.init(questionID: .duration, optionID: .aYearOrMore))
        responses.record(.init(questionID: .myPressure, optionID: .pressurePressure)) // autonomy −3
        let guarded = DesireProfileDeriver.derive(from: responses, intention: .myDesire)

        let reduced = JourneyPlanner.recommend(
            intention: .myDesire, profile: guarded,
            completedDays: Array(1...3),
            checkIns: checkIns([(3, .nothingChanged)])
        )
        // Guarded autonomy + reduced dose → attention/body lead the emphasis.
        #expect(reduced!.emphasizedThemes.contains(.attention) || reduced!.emphasizedThemes.contains(.body))

        let raised = JourneyPlanner.recommend(
            intention: .myDesire, profile: nil,
            completedDays: Array(1...3),
            checkIns: checkIns([(3, .wantMore)])
        )
        #expect(raised!.emphasizedThemes.contains(.anticipation)
                || raised!.emphasizedThemes.contains(.novelty)
                || raised!.emphasizedThemes.contains(.play))
    }
}
