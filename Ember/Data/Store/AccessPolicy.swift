import Foundation

// MARK: - AccessPolicy
//
// Mission 004: EMBER is an ONGOING daily guide, not a 21-day course.
// The commercial gate therefore keys on COMPLETED DAILY SESSIONS — a count
// that only grows through real use and can never be reset by the calendar.
//
// FREE: onboarding, Desire Profile, and the first `freeSessionAllowance`
//        completed daily sessions — enough to genuinely understand EMBER.
// PREMIUM: unlimited ongoing daily guide + adaptive personalization +
//        full history/journal + couple mode.

nonisolated enum AccessPolicy {

    /// Completed daily sessions a free user may live before premium is asked.
    /// Deliberately small-library-proof: independent of day numbers.
    nonisolated static let freeSessionAllowance = 3

    /// Can this user begin another daily session?
    ///
    /// Deterministic pure function. `completedSessions` counts sessions whose
    /// Act was lived (see EmberStore.countCompletedSessions); it never decays,
    /// never resets at midnight, and is migrated from legacy completedDays so
    /// existing users are not silently downgraded to "brand new free".
    static func canStartDailySession(
        completedSessions: Int,
        entitlement: EntitlementState,
        now: Date = .now
    ) -> Bool {
        if completedSessions < freeSessionAllowance { return true }
        return EntitlementEngine.isUnlocked(.ongoingGuide, in: entitlement, now: now)
    }

    /// Legacy compatibility shim for the transition period: numbered days up
    /// to the old limit stay open for users mid-legacy-flow.
    static func canOpenLegacyDay(
        _ dayNumber: Int,
        completedSessions: Int,
        entitlement: EntitlementState,
        now: Date = .now
    ) -> Bool {
        if dayNumber <= EntitlementEngine.freeDayLimit { return true }
        return canStartDailySession(completedSessions: completedSessions,
                                    entitlement: entitlement, now: now)
    }
}
