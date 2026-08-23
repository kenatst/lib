import Foundation
import Testing
@testable import Ember

// MARK: - Adversarial planner probes (mission 003B self-review)
//
// Attacks the new progression model with histories that should never occur
// in production but MUST NOT break invariants if they do: duplicated slots,
// gapped completions, out-of-order completion timestamps, and check-ins
// arriving between recommendation calls.

@Suite("Planner adversarial history probes")
struct PlannerAdversarialHistoryTests {

    @Test("Duplicated history entries cannot re-serve or strand slots")
    func duplicatedHistory() {
        for intention in DesireIntention.allCases {
            // Corrupted store: same slot recorded three times.
            let rec = JourneyPlanner.recommend(
                intention: intention, profile: nil,
                completedDays: [1, 1, 1, 2, 2, 3],
                checkIns: []
            )
            #expect(rec?.dayNumber == 4, "\(intention): first uncompleted slot must be served")
        }
    }

    @Test("Gapped history fills holes before advancing")
    func gappedHistoryFillsHoles() {
        // User somehow completed 5 without 3 — hole-filling beats novelty.
        let rec = JourneyPlanner.recommend(
            intention: .myDesire, profile: nil,
            completedDays: [1, 2, 5], checkIns: []
        )
        #expect(rec?.dayNumber == 3, "the lowest uncompleted slot is served first")
    }

    @Test("plannedDay(number:) agrees with recommend's next position")
    func plannedDayMatchesRecommendation() {
        let profiles: [DesireProfile?] = [nil]
        for intention in DesireIntention.allCases {
            var completed: [Int] = []
            while completed.count < JourneyCatalog.totalDays {
                guard let rec = JourneyPlanner.recommend(
                    intention: intention, profile: nil,
                    completedDays: completed, checkIns: []
                ) else { break }

                let planned = JourneyPlanner.plannedDay(
                    number: rec.dayNumber,
                    intention: intention,
                    profile: nil,
                    checkIns: []
                )
                let directPlan = JourneyPlanner.planTheme(
                    intention: intention,
                    position: rec.dayNumber,
                    profile: nil,
                    intensity: rec.intensity
                )
                #expect(planned?.theme == directPlan.theme,
                        "\(intention) @\(rec.dayNumber): plannedDay and planTheme disagree")
                #expect(planned?.number == rec.dayNumber)

                completed.append(rec.dayNumber)
            }
        }
    }

    @Test("A check-in arriving between calls changes themes, never positions")
    func checkInBurstsNeverMovePosition() {
        for intention in DesireIntention.allCases {
            let completed: [Int] = [1, 2, 3]
            let calm = JourneyPlanner.recommend(
                intention: intention, profile: nil,
                completedDays: completed,
                checkIns: [CheckIn(dayNumber: 3, response: .nothingChanged, date: .now)]
            )
            let eager = JourneyPlanner.recommend(
                intention: intention, profile: nil,
                completedDays: completed,
                checkIns: [CheckIn(dayNumber: 3, response: .wantMore, date: .now)]
            )

            // Position identical; only theme/intensity/pacing may differ.
            #expect(calm?.dayNumber == eager?.dayNumber,
                    "\(intention): a check-in burst must not move the progression position")

            // And whatever theme each serves, the slot is the same one.
            if let day = calm?.dayNumber {
                #expect((4...21).contains(day))
            }
        }
    }
}
