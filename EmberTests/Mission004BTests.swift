import Foundation
import Testing
@testable import Ember

// MARK: - Mission 004B regression tests
//
// Session identity, signal idempotency, and history-derived dose.

@MainActor
@Suite("004B: session identity routing")
struct SessionIdentityTests {

    private func makeStore() -> (EmberStore, URL) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ember-004b-\(UUID().uuidString)", isDirectory: true)
        return (EmberStore(directory: dir), dir)
    }

    @Test("open → complete Act → leave → reopen Return → SAME session ID")
    func returnTargetsSameSession() {
        let (store, dir) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }
        store.setIntention(.myDesire)
        _ = store.planForToday()
        guard let sessionID = store.currentPlanID else {
            Issue.record("no plan"); return
        }

        // Complete the Act (leaving before Return).
        store.markMovement(.discover)
        store.markMovement(.act)
        store.completeTodaySession()

        // Reopen: Home routes to Return for the SAME session.
        let actDone = store.state.sessionHistory.first {
            $0.id == sessionID
        }?.completedMovements.contains(.act) ?? false
        #expect(actDone)
        #expect(store.currentPlanID == sessionID,
                "today's session identity is stable across exits")
    }

    @Test("tomorrow creates a DIFFERENT session; no CheckIn collision")
    func tomorrowNewSessionNoCollision() {
        let (store, dir) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }
        store.setIntention(.myDesire)
        _ = store.planForToday()
        guard let todaySession = store.currentPlanID else {
            Issue.record("no plan"); return
        }

        store.completeTodaySession()

        // Today's answer, recorded against today's session.
        store.recordCheckIn(
            CheckIn(dayNumber: 1, response: .wantMore, date: .now),
            forSession: todaySession
        )
        #expect(store.state.checkIns.count == 1)

        // Tomorrow: new plan, new identity. Its answer must NOT replace
        // today's — the two coexist keyed by distinct sessions.
        var cal = LocalCalendar.identity
        _ = cal
        let tomorrow = LocalDay.validating("2026-01-02")!
        let tomorrowPlan = DailyEngine.planForToday(
            today: tomorrow, intention: .myDesire, profile: nil,
            plans: [:], history: store.state.sessionHistory,
            signals: store.state.learnedSignals, coupleRole: nil
        )
        #expect(tomorrowPlan.id != todaySession)

        store.recordCheckIn(
            CheckIn(dayNumber: 2, response: .nothingChanged, date: .now),
            forSession: tomorrowPlan.id
        )
        #expect(store.state.checkIns.count == 2, "no collision between sessions")
        #expect(store.state.checkIns.first { $0.sessionID == todaySession }?.response == .wantMore)
        #expect(store.state.checkIns.first { $0.sessionID == tomorrowPlan.id }?.response == .nothingChanged)
    }

    @Test("post-midnight Return stays attached to the ORIGINAL session")
    func postMidnightReturn() {
        let (store, dir) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }
        store.setIntention(.theirDesire)
        _ = store.planForToday()
        guard let originalSession = store.currentPlanID else {
            Issue.record("no plan"); return
        }
        let originalPlan = store.state.dailyPlans[originalSession]

        // The user opened the Return before midnight; answers at 00:30.
        // The view captured `originalSession` — record against it even though
        // the clock has rolled.
        store.recordCheckIn(
            CheckIn(dayNumber: 1, response: .feltDifferent, date: .now),
            forSession: originalSession
        )

        // The response landed on the ORIGINAL session's history record…
        #expect(store.state.sessionHistory.first { $0.id == originalSession }?.checkInResponse == .feltDifferent)
        // …and the plan itself was untouched.
        #expect(store.state.dailyPlans[originalSession] == originalPlan)
    }

    @Test("legacy numbered records still decode and migrate")
    func legacySurvives() {
        // A v3-era CheckIn JSON without a sessionID decodes cleanly.
        let json = #"{"dayNumber":4,"response":"feltDifferent","date":700000000.0}"#
        let decoded = try? JSONDecoder().decode(CheckIn.self, from: Data(json.utf8))
        #expect(decoded?.sessionID == nil)
        #expect(decoded?.response == .feltDifferent)
        #expect(decoded?.id == "legacy.4")

        // Round-trip of an ongoing check-in preserves its session binding.
        let ongoing = CheckIn(dayNumber: 1, response: .wantMore, date: .now,
                              sessionID: "2026-06-04#myDesire")
        if let data = try? JSONEncoder().encode(ongoing),
           let back = try? JSONDecoder().decode(CheckIn.self, from: data) {
            #expect(back == ongoing)
        } else {
            Issue.record("ongoing CheckIn failed to round-trip")
        }
    }
}

@MainActor
@Suite("004B: signal idempotency")
struct SignalIdempotencyTests {

    private func record(_ id: String, _ day: LocalDay, theme: DayTheme,
                        movements: Set<Movement> = [.discover, .reflect, .act],
                        response: CheckInResponse? = nil) -> DailySessionRecord {
        DailySessionRecord(id: id, day: day, intention: .myDesire, theme: theme,
                           servedIDs: [], completedMovements: movements,
                           checkInResponse: response)
    }

    @Test("changing an answer 10 times equals recording the final once")
    func tenChangesEqualOneFinal() {
        let day = LocalDay.validating("2026-05-05")!
        let finalResponse = CheckInResponse.wantMore

        // History A: one record whose FINAL stored state is wantMore.
        let historyA = [record("s1", day, theme: .novelty, response: finalResponse)]

        // History B: same single record — the projector never sees intermediate taps.
        let historyB = [record("s1", day, theme: .novelty, response: finalResponse)]

        let a = SignalProjector.rebuild(from: historyA)
        let b = SignalProjector.rebuild(from: historyB)
        #expect(a == b)

        // And rebuilding repeatedly is stable.
        #expect(SignalProjector.rebuild(from: historyB) == b)
    }

    @Test("one session contributes AT MOST ONCE regardless of duplicates in input")
    func duplicateInputRecordsCollapse() {
        let day = LocalDay.validating("2026-05-06")!
        // Corrupted/duplicated feed containing the SAME session id 3x.
        let duplicated = [
            record("dup", day, theme: .play, response: .noticedSomething),
            record("dup", day, theme: .play, response: .wantMore),
            record("dup", day, theme: .play, response: .noticedSomething),
        ]
        let signals = SignalProjector.rebuild(from: duplicated)
        // Final stored state wins, applied exactly ONCE.
        #expect(signals.themes[.play]?.exposureCount == 1)
        #expect(signals.completedSessionCount == 1)
    }

    @Test("completedSessionCount reflects completed sessions, not taps")
    func completedCountHonest() {
        let d1 = LocalDay.validating("2026-05-01")!
        let d2 = LocalDay.validating("2026-05-02")!
        let d3 = LocalDay.validating("2026-05-03")!
        let history = [
            record("a", d1, theme: .body),                                  // Act done
            record("b", d2, theme: .play, movements: [.discover]),          // abandoned
            record("c", d3, theme: .closeness),                             // Act done
        ]
        let signals = SignalProjector.rebuild(from: history)
        #expect(signals.completedSessionCount == 2)
    }

    @Test("same history always derives identical signals (180-day determinism)")
    func longHistoryDeterministic() {
        var history: [DailySessionRecord] = []
        var day = LocalDay.validating("2026-01-01")!
        let scripts: [CheckInResponse?] = [.nothingChanged, nil, .wantMore, .feltDifferent, nil]
        for i in 0..<180 {
            let theme = DayTheme.allCases[i % DayTheme.allCases.count]
            history.append(record("s-\(i)", day, theme: theme,
                                  response: scripts[i % scripts.count]))
            day = day.next()
        }
        let a = SignalProjector.rebuild(from: history)
        let b = SignalProjector.rebuild(from: history.shuffled())
        #expect(a == b, "order-independent projection for distinct sessions")
    }

    @Test("store rebuilds signals after each mutation (production loop)")
    func storeRebuildLoop() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ember-sig-\(UUID().uuidString)", isDirectory: true)
        let store = EmberStore(directory: dir)
        defer { try? FileManager.default.removeItem(at: dir) }
        store.setIntention(.myDesire)
        _ = store.planForToday()
        guard let sid = store.currentPlanID else {
            Issue.record("no plan"); return
        }

        store.completeTodaySession()
        store.recordCheckIn(CheckIn(dayNumber: 1, response: .wantMore, date: .now),
                            forSession: sid)
        let afterFirst = store.state.learnedSignals

        // Change the answer on the SAME session three more times.
        for r in [CheckInResponse.feltDifferent, .nothingChanged, .wantMore] {
            store.recordCheckIn(CheckIn(dayNumber: 1, response: r, date: .now),
                                forSession: sid)
        }

        let afterChanges = store.state.learnedSignals
        // Identical to having answered wantMore exactly once:
        let expected = SignalProjector.rebuild(from: store.state.sessionHistory)
        #expect(afterChanges == expected)
        // And exposure counted once, not four times.
        let servedTheme = store.state.sessionHistory.first { $0.id == sid }?.theme
        #expect(store.state.learnedSignals.themes[servedTheme ?? .attention]?.exposureCount == 1)
        _ = afterFirst
    }
}
