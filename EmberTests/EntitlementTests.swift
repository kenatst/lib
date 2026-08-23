import Foundation
import Testing
@testable import Ember

// MARK: - Entitlement engine & gates
//
// Pure-logic tests for the money path. StoreKit itself is exercised on
// simulator via the local .storekit configuration; these tests prove the
// DECISION layer can never become inconsistent.

@Suite("Entitlement engine")
struct EntitlementEngineTests {

    private let now = Date(timeIntervalSince1970: 1_000_000_000)
    private let annual = EntitlementEngine.annualProductID

    @Test("Free tier: first three days open, everything else gated")
    func freeDayGate() {
        #expect(EntitlementEngine.isFreeDay(1))
        #expect(EntitlementEngine.isFreeDay(3))
        #expect(!EntitlementEngine.isFreeDay(4))

        let free = EntitlementState.free
        #expect(EntitlementEngine.canOpenDay(1, entitlement: free, now: now))
        #expect(EntitlementEngine.canOpenDay(3, entitlement: free, now: now))
        #expect(!EntitlementEngine.canOpenDay(4, entitlement: free, now: now))
        #expect(!EntitlementEngine.canOpenDay(21, entitlement: free, now: now))
    }

    @Test("Active subscription opens all days")
    func activeSubscription() {
        var state = EntitlementState.free
        state = EntitlementEngine.apply(
            transaction: VerifiedTransaction(
                kind: .active(productID: annual, expiresAt: now.addingTimeInterval(86_400)),
                transactionID: 1
            ),
            to: state
        )
        #expect(state.isActive)
        for day in 1...21 {
            #expect(EntitlementEngine.canOpenDay(day, entitlement: state, now: now))
        }
    }

    @Test("Expired-but-unrenewed never grants access even without a revocation event")
    func expiryEnforced() {
        var state = EntitlementState.free
        state = EntitlementEngine.apply(
            transaction: VerifiedTransaction(
                kind: .active(productID: annual, expiresAt: now.addingTimeInterval(-1)), // expired
                transactionID: 2
            ),
            to: state
        )
        // isActive flag may still be set (StoreKit hasn't notified yet), but the
        // time-aware gate refuses.
        #expect(!EntitlementEngine.isUnlocked(.fullJourney, in: state, now: now))
        #expect(!EntitlementEngine.canOpenDay(4, entitlement: state, now: now))
    }

    @Test("Revocation deactivates immediately and leaves honest memory")
    func revocation() {
        var state = EntitlementState.free
        state = EntitlementEngine.apply(
            transaction: VerifiedTransaction(
                kind: .active(productID: annual, expiresAt: now.addingTimeInterval(86_400)),
                transactionID: 3
            ),
            to: state
        )
        #expect(state.isActive)

        state = EntitlementEngine.apply(
            transaction: VerifiedTransaction(kind: .revoked(productID: annual), transactionID: 4),
            to: state
        )
        #expect(!state.isActive)
        #expect(state.wasRevoked)
        // Revocation returns the user to the FREE tier: the preview stays
        // open (never punitive), but every premium day locks again.
        #expect(EntitlementEngine.canOpenDay(2, entitlement: state, now: now))
        #expect(!EntitlementEngine.canOpenDay(4, entitlement: state, now: now))
    }

    @Test("Unknown product IDs never unlock anything")
    func foreignProductsIgnored() {
        var state = EntitlementState.free
        state = EntitlementEngine.apply(
            transaction: VerifiedTransaction(
                kind: .active(productID: "com.other.app.premium", expiresAt: nil),
                transactionID: 5
            ),
            to: state
        )
        #expect(!state.isActive)
    }
}

// MARK: - Gate consistency with the journey contract

@Suite("Premium gates")
struct PremiumGateTests {

    @Test("Free preview covers exactly the days the paywall claims")
    func previewContract() {
        #expect(EntitlementEngine.freeDayLimit >= 3)
        #expect(EntitlementEngine.freeDayLimit < JourneyCatalog.totalDays)

        // The three journeys' day-4 content differs; all of it is premium.
        for intention in DesireIntention.allCases {
            let day4 = JourneyCatalog.day(4, for: intention)
            #expect(day4 != nil)
            #expect(!EntitlementEngine.isFreeDay(4))
        }
    }
}
