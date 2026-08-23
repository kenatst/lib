import Foundation
import Testing
@testable import Ember

// MARK: - JourneyPlanner: exhaustive journey simulations
//
// These are INVARIANT tests, not single-call tests. Every simulation runs a
// complete 21-step journey and asserts exhaustion, uniqueness, termination,
// determinism and bounded adaptation.

@Suite("JourneyPlanner invariants (full-journey simulations)")
struct JourneyPlannerSimulationTests {

    // MARK: Simulation harness

    /// Simulates a full journey to exhaustion. Returns served positions.
    private func simulate(
        intention: DesireIntention,
        profile: DesireProfile?,
        checkInScript: @escaping (Int) -> CheckInResponse
    ) -> [Int] {
        var completed: [Int] = []
        var served: [Int] = []
        var steps = 0

        while completed.count < JourneyCatalog.totalDays {
            steps += 1
            #expect(steps <= JourneyCatalog.totalDays,
                    "\(intention): journey did not terminate in 21 steps")

            guard let rec = JourneyPlanner.recommend(
                intention: intention,
                profile: profile,
                completedDays: completed,
                checkIns: completed.map { CheckIn(dayNumber: $0, response: checkInScript($0), date: .now) }
            ) else { break }

            served.append(rec.dayNumber)
            completed.append(rec.dayNumber)
        }
        return served
    }

    private func assertInvariants(_ intention: DesireIntention, _ served: [Int]) {
        let expected = Array(1...JourneyCatalog.totalDays)
        #expect(served == expected,
                "\(intention): served \(served) — missing \(Set(expected).subtracting(Set(served)))")
        #expect(Set(served).count == JourneyCatalog.totalDays, "\(intention): duplicates present")
        #expect(served.count == JourneyCatalog.totalDays, "\(intention): journey exhausted early")
    }

    // MARK: Profiles

    private func profile(_ intention: DesireIntention, _ answers: [(Onboarding.QuestionID, Onboarding.OptionID)]) -> DesireProfile {
        var responses = Onboarding.Responses()
        for (q, o) in answers {
            responses.record(.init(questionID: q, optionID: o))
        }
        return DesireProfileDeriver.derive(from: responses, intention: intention)
    }

    private func anticipationProfile() -> DesireProfile {
        var r = Onboarding.Responses()
        r.record(.init(questionID: .duration, optionID: .weeks))                       // anticipation +
        r.record(.init(questionID: .myState, optionID: .longingWithoutShape))          // anticipation ++
        return DesireProfileDeriver.derive(from: r, intention: .myDesire)
    }

    private func guardedSafetyProfile() -> DesireProfile {
        var r = Onboarding.Responses()
        r.record(.init(questionID: .duration, optionID: .aYearOrMore))
        r.record(.init(questionID: .stress, optionID: .stressHeavy))                   // emotionalSafety −−
        return DesireProfileDeriver.derive(from: r, intention: .theirDesire)
    }

    private func bodyLedProfile() -> DesireProfile {
        var r = Onboarding.Responses()
        r.record(.init(questionID: .duration, optionID: .creptUp))                     // selfConnection −
        r.record(.init(questionID: .mySelfConnection, optionID: .atEaseDistant))       // selfConnection −−
        return DesireProfileDeriver.derive(from: r, intention: .ourDesire)
    }

    // MARK: The matrix

    @Test("Every intention × nil profile × every uniform check-in exhausts all 21 slots uniquely")
    func fullMatrixNilProfile() {
        let scripts: [(String, (Int) -> CheckInResponse)] = [
            ("nothingChanged", { _ in .nothingChanged }),
            ("noticedSomething", { _ in .noticedSomething }),
            ("feltDifferent", { _ in .feltDifferent }),
            ("wantMore", { _ in .wantMore }),
        ]
        for intention in DesireIntention.allCases {
            for (name, script) in scripts {
                let served = simulate(intention: intention, profile: nil, checkInScript: script)
                #expect(Set(served).count == 21, "\(intention)/\(name): uniqueness broken")
                #expect(Set(served) == Set(1...21), "\(intention)/\(name): omission — missing \(Set(1...21).subtracting(Set(served)))")
                #expect(served.count == 21, "\(intention)/\(name): did not terminate after all slots")
            }
        }
    }

    @Test("Realistic profiles under mixed check-in histories exhaust all 21 slots")
    func realisticProfilesMixedCheckIns() {
        let profiles: [(String, DesireProfile?)] = [
            ("anticipation", anticipationProfile()),
            ("guarded-safety", guardedSafetyProfile()),
            ("body-led", bodyLedProfile()),
            ("nil", nil),
        ]

        // Alternating wantMore / nothingChanged / feltDifferent history.
        let mixed: (Int) -> CheckInResponse = { day in
            switch day % 3 {
            case 0: return .wantMore
            case 1: return .nothingChanged
            default: return .feltDifferent
            }
        }
        // Escalating then settling.
        let escalating: (Int) -> CheckInResponse = { day in
            day < 7 ? .wantMore : (day < 14 ? .feltDifferent : .nothingChanged)
        }
        // Stuck then waking.
        let stuck: (Int) -> CheckInResponse = { day in
            day < 10 ? .nothingChanged : (day < 15 ? .noticedSomething : .wantMore)
        }

        for intention in DesireIntention.allCases {
            for (name, profileValue) in profiles {
                for (scriptName, script) in [("mixed", mixed), ("escalating", escalating), ("stuck", stuck)] {
                    let served = simulate(intention: intention, profile: profileValue, checkInScript: script)
                    #expect(served == Array(1...21),
                            "\(intention)/\(name)/\(scriptName): \(served)")
                }
            }
        }
    }

    @Test("Simulations are deterministic across repeated runs")
    func deterministicAcrossRuns() {
        for intention in DesireIntention.allCases {
            let a = simulate(intention: intention, profile: anticipationProfile(), checkInScript: { $0 % 2 == 0 ? .wantMore : .noticedSomething })
            let b = simulate(intention: intention, profile: anticipationProfile(), checkInScript: { $0 % 2 == 0 ? .wantMore : .noticedSomething })
            #expect(a == b, "\(intention): nondeterministic sequence")
        }
    }

    @Test("Adaptation still happens (personalization not weakened away)")
    func adaptationStillOccurs() {
        // A raised-dose user must see at least one adapted position somewhere.
        for intention in DesireIntention.allCases {
            var completed: [Int] = []
            var adaptedCount = 0
            while completed.count < JourneyCatalog.totalDays {
                guard let rec = JourneyPlanner.recommend(
                    intention: intention,
                    profile: anticipationProfile(),
                    completedDays: completed,
                    checkIns: [CheckIn(dayNumber: max(1, completed.count), response: .wantMore, date: .now)]
                ) else { break }
                if rec.isAdapted { adaptedCount += 1 }
                completed.append(rec.dayNumber)
            }
            #expect(adaptedCount > 0, "\(intention): no adaptation occurred anywhere — personalization lost")
        }
    }

    @Test("Adapted sequences differ between intentions (differentiation preserved)")
    func differentiationPreserved() {
        let script: (Int) -> CheckInResponse = { $0 % 3 == 0 ? .wantMore : .feltDifferent }
        func themeSequence(_ intention: DesireIntention, _ profileValue: DesireProfile?) -> [DayTheme] {
            var completed: [Int] = []
            var themes: [DayTheme] = []
            while completed.count < JourneyCatalog.totalDays {
                guard let rec = JourneyPlanner.recommend(
                    intention: intention, profile: profileValue,
                    completedDays: completed,
                    checkIns: completed.map { CheckIn(dayNumber: $0, response: script($0), date: .now) }
                ) else { break }
                themes.append(JourneyPlanner.planTheme(
                    intention: intention, position: rec.dayNumber,
                    profile: profileValue, intensity: rec.intensity
                ).theme)
                completed.append(rec.dayNumber)
            }
            return themes
        }

        let my = themeSequence(.myDesire, anticipationProfile())
        let their = themeSequence(.theirDesire, nil)
        let our = themeSequence(.ourDesire, bodyLedProfile())
        #expect(my != their && my != our && their != our)
    }

    @Test("Anchors remain respected: anchor themes never deferred past their beat")
    func anchorsRespected() {
        for intention in DesireIntention.allCases {
            let shape = JourneyShape.shape(for: intention)
            var completed: [Int] = []
            var assignedThemes: [Int: DayTheme] = [:]
            while completed.count < JourneyCatalog.totalDays {
                guard let rec = JourneyPlanner.recommend(
                    intention: intention, profile: guardedSafetyProfile(),
                    completedDays: completed,
                    checkIns: completed.map { CheckIn(dayNumber: $0, response: $0 % 2 == 0 ? .wantMore : .nothingChanged, date: .now) }
                ) else { break }
                let plan = JourneyPlanner.planTheme(
                    intention: intention, position: rec.dayNumber,
                    profile: guardedSafetyProfile(), intensity: rec.intensity
                )
                assignedThemes[rec.dayNumber] = plan.theme
                completed.append(rec.dayNumber)
            }
            // Each anchor position still carries its own natural theme.
            for anchor in shape.anchorDays {
                #expect(assignedThemes[anchor] == shape.theme(for: anchor),
                        "\(intention): anchor day \(anchor) lost its theme")
            }
        }
    }

    @Test("Position never exceeds totalDays and recommendation is nil only when finished")
    func boundsAndTermination() {
        for intention in DesireIntention.allCases {
            #expect(JourneyPlanner.recommend(intention: intention, profile: nil,
                                             completedDays: Array(1...20), checkIns: []) != nil)
            #expect(JourneyPlanner.recommend(intention: intention, profile: nil,
                                             completedDays: Array(1...21), checkIns: []) == nil)

            // Duplicated history cannot corrupt the position.
            let rec = JourneyPlanner.recommend(intention: intention, profile: nil,
                                               completedDays: [1, 2, 2, 3], checkIns: [])
            #expect(rec?.dayNumber == 4, "position derives from count of lived experiences, not max()")
        }
    }
}
