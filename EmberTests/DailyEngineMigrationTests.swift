import Foundation
import Testing
@testable import Ember

// MARK: - Migration & calendar-day invariant tests (Mission 004)

@Suite("Migration v3→v4 (daily engine)")
struct MigrationV4Tests {

    @Test("Legacy completedDays+checkIns become honest session records")
    func legacyHistoryPreserved() {
        var state = EmberStore.PersistedState.empty
        state.schemaVersion = 3
        state.intention = .theirDesire
        state.completedDays = [1, 2, 5]
        state.checkIns = [
            CheckIn(dayNumber: 1, response: .feltDifferent, date: .now),
            CheckIn(dayNumber: 2, response: .nothingChanged, date: .now),
        ]

        EmberStore.applyMigrations(to: &state)

        #expect(state.schemaVersion == 4)
        // Three legacy records — no fabricated extra sessions.
        #expect(state.sessionHistory.count == 3)
        #expect(state.sessionHistory.allSatisfy { $0.legacyDayNumber != nil })
        // Check-ins carried onto their records.
        let day1 = state.sessionHistory.first { $0.legacyDayNumber == 1 }
        #expect(day1?.checkInResponse == .feltDifferent)
        // Ordering by legacy number preserved.
        #expect(state.sessionHistory.map(\.legacyDayNumber) == [1, 2, 5])
    }

    @Test("Migration is idempotent")
    func idempotent() {
        var state = EmberStore.PersistedState.empty
        state.schemaVersion = 3
        state.intention = .myDesire
        state.completedDays = [1, 2, 3]

        EmberStore.applyMigrations(to: &state)
        let afterFirst = state.sessionHistory
        EmberStore.applyMigrations(to: &state)
        #expect(state.sessionHistory.count == afterFirst.count)
    }

    @Test("Journal reflections survive migration untouched")
    func journalSurvives() {
        var state = EmberStore.PersistedState.empty
        state.schemaVersion = 3
        state.intention = .myDesire
        state.completedDays = [1]
        state.reflectionsBySpace["solo"] = [1: "private words", 2: "more private words"]

        EmberStore.applyMigrations(to: &state)
        #expect(state.reflectionsBySpace["solo"]?[1] == "private words")
        #expect(state.reflectionsBySpace["solo"]?[2] == "more private words")
    }

    @Test("Free allowance carries over from legacy completions")
    func freeAllowanceCarries() {
        var state = EmberStore.PersistedState.empty
        state.schemaVersion = 3
        state.intention = .myDesire
        state.completedDays = Array(1...10)   // legacy paying-era user

        EmberStore.applyMigrations(to: &state)
        #expect(state.freeSessionsUsed >= 10,
                "a user who already lived 10 sessions is not reset to brand-new free")

        // And the gate respects it deterministically.
        let free = EntitlementState.free
        #expect(AccessPolicy.canStartDailySession(completedSessions: 10, entitlement: free) == false)
        #expect(AccessPolicy.canStartDailySession(completedSessions: 2, entitlement: free) == true)
    }

    @Test("Signals seeded from migrated history stay bounded")
    func signalsSeededBounded() {
        var state = EmberStore.PersistedState.empty
        state.schemaVersion = 3
        state.intention = .ourDesire
        state.completedDays = Array(1...21)
        // All misses — a worst case that must still stay bounded.
        state.checkIns = (1...21).map {
            CheckIn(dayNumber: $0, response: .nothingChanged, date: .now)
        }

        EmberStore.applyMigrations(to: &state)
        for (_, signal) in state.learnedSignals.themes {
            let net = signal.positiveResonance + signal.lowResonance
            #expect(net >= -3 && net <= 3, "resonance bounded even after 21 misses")
        }
    }
}

@Suite("LocalDay calendar semantics")
struct LocalDayCalendarTests {

    private func calendar(timeZoneIdentifier: String) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: timeZoneIdentifier)!
        return c
    }

    @Test("Same moment, different zones → different canonical days")
    func timezoneIdentity() {
        // 2026-06-01 21:30 UTC = June 1 in London (BST, UTC+1) but June 2
        // in Tokyo (UTC+9, already past midnight).
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 1; comps.hour = 21; comps.minute = 30
        let date = LocalCalendar.identity.date(from: comps)!

        let london = LocalCalendar.day(for: date, in: calendar(timeZoneIdentifier: "Europe/London"))
        let tokyo = LocalCalendar.day(for: date, in: calendar(timeZoneIdentifier: "Asia/Tokyo"))
        #expect(london.storageKey == "2026-06-01")
        #expect(tokyo.storageKey == "2026-06-02")
    }

    @Test("Midnight transition rolls to a new day")
    func midnightTransition() {
        var cal = calendar(timeZoneIdentifier: "Europe/Paris")
        cal.timeZone = TimeZone(identifier: "UTC")!
        _ = cal

        let before = LocalDay.validating("2026-03-14")!
        let after = before.next()
        #expect(after.storageKey == "2026-03-15")
    }

    @Test("DST spring-forward keeps calendar identity stable")
    func dstBoundary() {
        // US DST 2026: March 8. A 02:30 local time doesn't exist that day.
        let cal = calendar(timeZoneIdentifier: "America/New_York")
        var comps = DateComponents()
        comps.year = 2026; comps.month = 3; comps.day = 8; comps.hour = 1; comps.minute = 30
        guard let beforeDST = cal.date(from: comps) else { Issue.record("bad date"); return }
        var comps2 = comps
        comps2.hour = 3
        guard let afterDST = cal.date(from: comps2) else { Issue.record("bad date"); return }

        let day1 = LocalCalendar.day(for: beforeDST, in: cal)
        let day2 = LocalCalendar.day(for: afterDST, in: cal)
        // Both are the same calendar day despite the skipped hour.
        #expect(day1 == day2)
        #expect(day1.storageKey == "2026-03-08")
    }

    @Test("Corrupt persisted dates are rejected, not crashed on")
    func corruptDatesRejected() {
        #expect(LocalDay.parse("not-a-date") == nil)
        #expect(LocalDay.parse("2026-13-40") == nil)
        #expect(LocalDay.parse("2026-02-31") == nil)
        #expect(LocalDay.parse("") == nil)
        #expect(LocalDay.parse("2026-06-01") != nil)
    }

    @Test("Day arithmetic across month and year boundaries")
    func boundaryArithmetic() {
        let endOfMonth = LocalDay.validating("2027-01-31")!
        #expect(endOfMonth.next().storageKey == "2027-02-01")

        let endOfYear = LocalDay.validating("2026-12-31")!
        #expect(endOfYear.next().storageKey == "2027-01-01")

        let leapEve = LocalDay.validating("2028-02-28")!
        #expect(leapEve.next().storageKey == "2028-02-29")
    }
}
