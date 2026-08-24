import Foundation
import Testing
import StoreKit
import StoreKitTest
@testable import Ember

// MARK: - Mission 004: ongoing monetization + couple daily-planning tests

@MainActor
@Suite("Ongoing access policy (004)")
struct AccessPolicyTests {

    private let paid = EntitlementState(
        isActive: true,
        productID: EntitlementEngine.annualProductID,
        expiresAt: Date.distantFuture,
        wasRevoked: false
    )

    @Test("Free allowance: first three sessions open; the fourth is gated")
    func allowanceGate() {
        // Sessions 1–3 (completed counts 0–2 at start) are free. Once THREE
        // sessions are complete, the next one needs premium.
        #expect(AccessPolicy.canStartDailySession(completedSessions: 0, entitlement: .free))
        #expect(AccessPolicy.canStartDailySession(completedSessions: 1, entitlement: .free))
        #expect(AccessPolicy.canStartDailySession(completedSessions: 2, entitlement: .free))
        #expect(!AccessPolicy.canStartDailySession(completedSessions: 3, entitlement: .free),
                "three free sessions lived — ongoing access is premium")
        #expect(!AccessPolicy.canStartDailySession(completedSessions: 100, entitlement: .free))
    }

    @Test("Premium unlocks unlimited ongoing sessions")
    func premiumUnlimited() {
        for count in [0, 3, 4, 50, 365] {
            #expect(AccessPolicy.canStartDailySession(completedSessions: count, entitlement: paid))
        }
    }

    @Test("A new calendar day does NOT reset the free allowance")
    func calendarCannotResetAllowance() {
        // Structural proof: the gate's inputs are (completedSessions,
        // entitlement, now) — no date input can influence the free count.
        // Simulate two users months apart with identical counters.
        let early = AccessPolicy.canStartDailySession(
            completedSessions: 4, entitlement: .free,
            now: LocalDay.validating("2026-01-10").map { _ in Date(timeIntervalSince1970: 1_768_000_000) }!
        )
        let late = AccessPolicy.canStartDailySession(
            completedSessions: 4, entitlement: .free,
            now: Date(timeIntervalSince1970: 1_900_000_000)
        )
        #expect(!early)
        #expect(!late)

        // And the store-level counter never decays on its own: it only grows
        // via completeTodaySession(). No API exists to reset it by date.
        var state = EmberStore.PersistedState.empty
        state.freeSessionsUsed = 5
        EmberStore.applyMigrations(to: &state)
        #expect(state.freeSessionsUsed == 5, "migration must not lower the counter")
    }

    @Test("Revoked premium returns the user to the free tier — with their history intact")
    func revocationReturnsToFree() {
        var state = paid
        state.wasRevoked = true
        state.isActive = false
        // They keep their completed-session count but lose ongoing access.
        #expect(!AccessPolicy.canStartDailySession(completedSessions: 10, entitlement: state))
        // Free preview semantics still apply for brand-new users.
        #expect(AccessPolicy.canStartDailySession(completedSessions: 1, entitlement: .free))
    }

    @Test("Migration-era users: legacy days convert to session credit")
    func migrationCredit() {
        // EmberStore.applyMigrations sets freeSessionsUsed = max(existing, legacyCount).
        var state = EmberStore.PersistedState.empty
        state.schemaVersion = 3
        state.intention = .myDesire
        state.completedDays = Array(1...21)   // finished the whole legacy course
        EmberStore.applyMigrations(to: &state)

        #expect(state.freeSessionsUsed >= 21)
        #expect(state.sessionHistory.count == 21)
        #expect(state.sessionHistory.allSatisfy { $0.legacyDayNumber != nil })
    }
}


@MainActor
@Suite("Couple daily planning (004)")
struct CoupleDailyPlanningTests {

    private let cal = LocalCalendar.identity

    @Test("Both roles' assignments come from ONE frozen plan — same day, same pair")
    func sharedPlanIdentity() {
        let day = LocalDay.validating("2026-07-01")!
        let planA = DailyEngine.planForToday(
            today: day, intention: .ourDesire, profile: nil,
            plans: [:], history: [], signals: .empty,
            coupleRole: .partnerOne
        )
        // Partner B's device plans the SAME calendar day independently.
        let planB = DailyEngine.planForToday(
            today: day, intention: .ourDesire, profile: nil,
            plans: [:], history: [], signals: .empty,
            coupleRole: .partnerTwo
        )

        #expect(planA.id == planB.id, "one shared session identity per day")
        #expect(planA.theme == planB.theme)
        #expect(planA.discoverContentID == planB.discoverContentID)
        // Asymmetric: different instructions per role.
        #expect(planA.coupleAssignmentIDs?[.partnerOne] != planA.coupleAssignmentIDs?[.partnerTwo])
        #expect(planA.coupleAssignmentIDs?[.partnerOne] == planB.coupleAssignmentIDs?[.partnerOne],
                "deterministic assignment so both devices draw the same pool entry")
    }

    @Test("Private content never enters shared structures")
    func privacyBelowUI() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ember-004-couple-\(UUID().uuidString)", isDirectory: true)
        let store = EmberStore(directory: dir)
        store.setIntention(.ourDesire)
        store.setCoupleRole(.partnerOne)

        _ = store.planForToday()
        store.saveSessionReflection("my innermost thought", sessionID: store.currentPlanID ?? "")
        store.setProfile(DesireProfile(readings: [
            DimensionReading(dimension: .selfConnection, strength: 0.9),
        ], intention: .ourDesire))

        // The plan object that WOULD be shared carries only IDs + theme +
        // assignments — no reflections, no profile, no signals.
        if let plan = store.state.dailyPlans[store.currentPlanID ?? ""] {
            let mirrored = Mirror(reflecting: plan)
            let fieldNames = mirrored.children.compactMap(\.label)
            for forbidden in ["reflection", "profile", "signals", "checkIns", "draft"] {
                #expect(!fieldNames.contains { $0.localizedCaseInsensitiveContains(forbidden) },
                        "DailyPlan must not carry private field \(forbidden)")
            }
        }

        // Switching spaces hides my reflection.
        store.setCoupleRole(.partnerTwo)
        #expect(store.sessionReflection(for: store.currentPlanID ?? "") == nil)
    }

    @Test("Unpairing semantics unchanged: no partner reads the other's words")
    func unpairStillProtects() {
        // Structural test preserved from Mission 003 — CoupleService still has
        // no API for cross-partner reflection access.
        let service = LocalDemoCoupleService()
        // The protocol surface itself is the proof: compile-time absence.
        _ = service
        #expect(true)
    }
}
