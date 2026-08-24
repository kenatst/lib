import Foundation

// MARK: - Entitlement model
//
// Pure subscription state — no StoreKit types leak past the service layer.
// Everything here is deterministically testable; `EntitlementEngine` decides
// what a transaction MEANS, `StoreService` only reports what happened.

nonisolated enum PremiumFeature: String, CaseIterable, Sendable {
    case ongoingGuide         // the ongoing daily guide beyond the free allowance
    case adaptivePlanner      // check-in-driven adaptation & emphasized variants
    case journal              // private reflections archive
    case coupleMode           // Our Desire spaces + asymmetric steps

    var nameKey: String { "paywall.feature.\(rawValue).name" }
    var detailKey: String { "paywall.feature.\(rawValue).detail" }
}

nonisolated struct EntitlementState: Equatable, Sendable {
    /// A purchase is active right now (subscription period valid).
    var isActive: Bool = false
    /// Product identifier backing the active entitlement, if any.
    var productID: String?
    /// Expiration of the current paid period, when known.
    var expiresAt: Date?
    /// True while a refund/revocation was observed — UI shows honest state.
    var wasRevoked: Bool = false

    static let free = EntitlementState()
}

/// The single decision-maker for transaction → entitlement transitions.
nonisolated enum EntitlementEngine {

    /// The one subscription EMBER sells. One product keeps the choice simple
    /// and dark-pattern-free: no tiers, no fake discounts, no countdowns.
    nonisolated static let annualProductID = "com.kenatst.ember.premium.annual"

    /// Apply a verified transaction to the current state.
    /// - renewals/extensions simply move the expiration forward
    /// - revocations (refunds, family-sharing loss) deactivate immediately
    static func apply(
        transaction: VerifiedTransaction,
        to state: EntitlementState
    ) -> EntitlementState {
        var next = state
        switch transaction.kind {
        case .active(let productID, let expiresAt):
            guard productID == annualProductID else { return next }
            next.isActive = true
            next.productID = productID
            next.expiresAt = expiresAt
            next.wasRevoked = false
        case .revoked:
            next = .free
            next.wasRevoked = true
        }
        return next
    }

    /// Whether a feature gate is open. Time-aware so an expired but un-renewed
    /// subscription never grants access even before StoreKit notifies us.
    static func isUnlocked(_ feature: PremiumFeature, in state: EntitlementState, now: Date) -> Bool {
        guard state.isActive else { return false }
        if let expiresAt = state.expiresAt {
            return now < expiresAt
        }
        return true
    }

    /// Free preview: the first few completed daily sessions demonstrate the
    /// full experience on any journey. Ongoing access beyond that is premium.
    /// Day NUMBERS no longer exist as product logic; this constant remains
    /// only for legacy-day compatibility during migration.
    nonisolated static let freeDayLimit = 3
    nonisolated static let freeSessionAllowance = AccessPolicy.freeSessionAllowance

    nonisolated static func isFreeDay(_ dayNumber: Int) -> Bool {
        dayNumber <= freeDayLimit
    }

    static func canOpenDay(_ dayNumber: Int, entitlement: EntitlementState, now: Date) -> Bool {
        // Legacy numbered-day flow (pre-daily-engine routes). New gating for
        // ongoing sessions lives in AccessPolicy/completedSessions.
        isFreeDay(dayNumber) || isUnlocked(.ongoingGuide, in: entitlement, now: now)
    }
}

// MARK: - Transaction DTO (decouples tests from StoreKit)

nonisolated struct VerifiedTransaction: Equatable, Sendable {
    nonisolated enum Kind: Equatable, Sendable {
        case active(productID: String, expiresAt: Date?)
        case revoked(productID: String)
    }

    let kind: Kind
    /// Stable identifier used to avoid double-applying the same transaction.
    let transactionID: UInt64
}
