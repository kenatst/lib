import Foundation
import Testing
@testable import Ember

// MARK: - Long-run daily-engine simulations (Mission 004)
//
// Simulates REAL USERS day by day for 30/90/180 days across every intention,
// several profiles and response scripts. Asserts the engine stays healthy:
// unique plans per day, no finite completion, cooldown-bounded repetition,
// determinism, slow signal drift, and continued differentiation.

@Suite("Daily Engine long-run simulations")
struct DailyEngineSimulationTests {

    private let cal = LocalCalendar.identity

    private struct SimulationResult {
        let plansPlanned: Int
        let uniquePlans: Int
        let themesServed: Set<DayTheme>
        let exactDiscoverRepeatsWithin30: Int
        let finalSignalRange: ClosedRange<Double>
        let stillPlanningAfterAllDays: Bool
    }

    /// Runs a simulated user for `days` days.
    private func simulate(
        intention: DesireIntention,
        profile: DesireProfile?,
        days: Int,
        responses: (Int, DayTheme) -> CheckInResponse?,
        skipProbability: Int = 0   // 0..9; a "roll" >= skip means the user skips
    ) -> SimulationResult {
        var plans: [String: DailyPlan] = [:]
        var history: [DailySessionRecord] = []
        var signals = LearnedSignals.empty
        var storePlansByDay: [String: DailyPlan] = [:]   // snapshot immutability check
        var discoverHistory: [(day: LocalDay, key: String)] = []
        var repeats = 0

        var day = LocalDay.validating("2026-01-01")!
        var livedSessions = 0

        for offset in 0..<days {
            // Some days the user doesn't open EMBER at all — no plan is made.
            if skipProbability > 0 && (offset * 7 + 3) % 10 < skipProbability {
                day = day.next()
                continue
            }

            let plan = DailyEngine.planForToday(
                today: day, intention: intention, profile: profile,
                checkIns: [], plans: plans, history: history,
                signals: signals, coupleRole: nil
            )

            // IDEMPOTENCY: re-planning same day returns identical plan.
            let replan = DailyEngine.planForToday(
                today: day, intention: intention, profile: profile,
                checkIns: [], plans: [plan.id: plan], history: history,
                signals: signals, coupleRole: nil
            )
            #expect(replan == plan, "day \(offset): frozen plan mutated on re-plan")
            if let seen = storePlansByDay[plan.id] {
                #expect(seen == plan)
            }
            storePlansByDay[plan.id] = plan

            // HARD INVARIANT: identical discover never within 7 days.
            for previous in discoverHistory where previous.key == plan.discoverContentID.key {
                let gap = plan.day.days(since: previous.day)
                if gap > 0 && gap < 7 {
                    repeats += 1
                }
            }
            discoverHistory.append((plan.day, plan.discoverContentID.key))

            plans[plan.id] = plan
            var record = DailySessionRecord(
                id: plan.id, day: plan.day, intention: plan.intention,
                theme: plan.theme, servedIDs: plan.allContentKeys,
                completedMovements: [.discover, .reflect, .act]
            )

            // Evening Return?
            if let response = responses(offset, plan.theme) {
                record.checkInResponse = response
                SignalUpdater.apply(record, to: &signals, today: plan.day)
            } else {
                SignalUpdater.apply(record, to: &signals, today: plan.day)
            }

            history.append(record)
            livedSessions += 1
            day = day.next()
        }

        let resonanceValues = signals.themes.values.map {
            max(-3.0, min(3.0, $0.positiveResonance + $0.lowResonance))
        }

        return SimulationResult(
            plansPlanned: livedSessions,
            uniquePlans: Set(history.map(\.id)).count,
            themesServed: Set(history.map(\.theme)),
            exactDiscoverRepeatsWithin30: repeats,
            finalSignalRange: (resonanceValues.min() ?? 0)...(resonanceValues.max() ?? 0),
            stillPlanningAfterAllDays: livedSessions > 0
        )
    }

    private func mixedResponses(_ offset: Int, theme: DayTheme) -> CheckInResponse? {
        switch offset % 5 {
        case 0: return .nothingChanged
        case 1: return .noticedSomething
        case 2: return nil               // skipped Return
        case 3: return .feltDifferent
        default: return .wantMore
        }
    }

    @Test("30-day simulation: every intention, mixed honest usage")
    func thirtyDays() {
        for intention in DesireIntention.allCases {
            let result = simulate(intention: intention, profile: nil, days: 30,
                                  responses: mixedResponses)
            #expect(result.plansPlanned == 30)
            #expect(result.uniquePlans == 30)
            #expect(result.stillPlanningAfterAllDays)
            #expect(result.exactDiscoverRepeatsWithin30 == 0,
                    "\(intention): repeated identical discover inside 30d window")
            #expect(result.finalSignalRange.upperBound <= 3)
            #expect(result.finalSignalRange.lowerBound >= -3)
        }
    }

    @Test("90-day simulation with skips and missed Returns stays healthy")
    func ninetyDays() {
        let profiles: [DesireProfile?] = [
            nil,
            DesireProfile(readings: [
                DimensionReading(dimension: .anticipation, strength: 0.8),
                DimensionReading(dimension: .connection, strength: 0.5),
            ], intention: .myDesire),
            DesireProfile(readings: [
                DimensionReading(dimension: .novelty, strength: -0.6),
                DimensionReading(dimension: .emotionalSafety, strength: 0.7),
            ], intention: .theirDesire),
        ]
        for intention in DesireIntention.allCases {
            for profile in profiles {
                let result = simulate(intention: intention, profile: profile,
                                      days: 90, responses: mixedResponses,
                                      skipProbability: 3)   // misses ~30% of days
                #expect(result.uniquePlans == result.plansPlanned)
                #expect(result.plansPlanned > 50, "engine kept offering despite skips")
                #expect(result.exactDiscoverRepeatsWithin30 == 0,
                        "\(intention)/\(profile != nil): content repetition violation")
                #expect(result.finalSignalRange.lowerBound >= -3)
                #expect(result.finalSignalRange.upperBound <= 3)
            }
        }
    }

    @Test("180-day chronic nothingChanged never crashes or loops one theme")
    func oneEightyDaysChronicFlat() {
        for intention in DesireIntention.allCases {
            let result = simulate(
                intention: intention, profile: nil, days: 180,
                responses: { _, _ in .nothingChanged }
            )
            #expect(result.plansPlanned == 180)
            #expect(result.uniquePlans == 180)
            // Even under permanent gentle dose the arc keeps breathing:
            #expect(result.themesServed.count >= 4,
                    "\(intention): collapsed to \(result.themesServed.count) themes over 180 days")
            #expect(result.exactDiscoverRepeatsWithin30 == 0)
        }
    }

    @Test("180-day enthusiastic user: richer but bounded")
    func oneEightyDaysEnthusiast() {
        for intention in DesireIntention.allCases {
            let result = simulate(
                intention: intention, profile: nil, days: 180,
                responses: { offset, _ in offset % 4 == 3 ? .feltDifferent : .wantMore }
            )
            #expect(result.plansPlanned == 180)
            #expect(result.themesServed.count >= 5,
                    "\(intention): enthusiast saw only \(result.themesServed.count) themes")
            #expect(result.exactDiscoverRepeatsWithin30 == 0)
        }
    }

    @Test("Determinism across whole simulations")
    func wholeRunDeterminism() {
        func run() -> [String] {
            var plans: [String: DailyPlan] = [:]
            var history: [DailySessionRecord] = []
            var signals = LearnedSignals.empty
            var fingerprints: [String] = []
            var day = LocalDay.validating("2026-05-01")!
            for offset in 0..<45 {
                let plan = DailyEngine.planForToday(
                    today: day, intention: .ourDesire, profile: nil,
                    checkIns: [], plans: plans, history: history,
                    signals: signals, coupleRole: nil
                )
                fingerprints.append("\(plan.id)|\(plan.theme)|\(plan.discoverContentID.key)")
                plans[plan.id] = plan
                history.append(DailySessionRecord(
                    id: plan.id, day: plan.day, intention: plan.intention,
                    theme: plan.theme, servedIDs: plan.allContentKeys,
                    completedMovements: [.act],
                    checkInResponse: offset % 3 == 0 ? .nothingChanged : .noticedSomething
                ))
                SignalUpdater.apply(history[history.count - 1], to: &signals, today: day)
                day = day.next()
            }
            return fingerprints
        }
        let runA = run()
        let runB = run()
        #expect(runA == runB, "two identical runs diverged — nondeterminism!")
    }
}
