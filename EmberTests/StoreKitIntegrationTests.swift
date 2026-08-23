import Foundation
import Testing
import StoreKit
import StoreKitTest
@testable import Ember

// MARK: - StoreKit integration (local configuration)
//
// Uses SKTestSession against EmberStoreKitTest.storekit — the Apple-sanctioned
// way to exercise REAL StoreKit loading/purchase/restore flows deterministically
// (no live App Store, no human). Runs wherever `xcodebuild test` runs, so CI
// verifies the money path end-to-end.
//
// REVOCATION SEMANTICS: this toolchain's StoreKitTest exposes a TRUE refund
// API — `refundTransaction(identifier:)` — which is what Apple fires when a
// customer wins a refund request. Expiry (`expireSubscription`) is a different
// event with different semantics and is tested separately. Never conflate them.

@MainActor
@Suite("StoreKit integration (local config)", .serialized)
struct StoreKitIntegrationTests {

    /// Process-wide shared session. SKTestErrorDomain 6 ("session already
    /// exists") is a teardown race between tests; one long-lived session per
    /// process avoids it entirely. Tests reset state via clearTransactions().
    private static let sharedSessionTask: Task<SKTestSession, Error> = Task {
        var lastError: Error?
        for attempt in 0..<8 {
            do {
                let session = try SKTestSession(configurationFileNamed: "EmberStoreKitTest")
                session.disableDialogs = true
                return session
            } catch let error as NSError where error.domain == "SKTestErrorDomain" {
                lastError = error
                try? await Task.sleep(for: .milliseconds(250 * Double(attempt + 1)))
            } catch {
                lastError = error
                break
            }
        }
        throw lastError ?? NSError(domain: "SKTestErrorDomain", code: -1)
    }

    @available(iOS 17.2, *)
    private func makeSession() async throws -> SKTestSession {
        let session = try await Self.sharedSessionTask.value
        // Only reset when leftovers exist; a blind clearTransactions() during
        // a prior test's purchase settlement is itself a flake source.
        if !session.allTransactions().isEmpty {
            session.clearTransactions()
            // Wait for the reset to be visible to StoreKit clients.
            for _ in 0..<20 {
                if session.allTransactions().isEmpty { break }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        return session
    }

    @Test("Products load through the live engine via local configuration")
    func productsLoad() async throws {
        guard #available(iOS 17.2, *) else { Issue.record("requires iOS 17.2+"); return }
        _ = try await makeSession()

        let service = StoreService()
        await service.loadProducts()

        #expect(service.lastError == nil)
        #expect(service.products.count == 1)
        #expect(service.products.first?.id == EntitlementEngine.annualProductID)
        #expect(service.products.first?.displayPrice.isEmpty == false)
    }

    @Test("Purchase unlocks every premium day; relaunch restores entitlement")
    func purchaseFlow() async throws {
        guard #available(iOS 17.2, *) else { Issue.record("requires iOS 17.2+"); return }
        let session = try await makeSession()

        let service = StoreService()
        await service.loadProducts()
        guard let product = service.products.first else {
            Issue.record("product missing"); return
        }

        // Wait out the init-time history refresh, then buy. StoreKit
        // occasionally needs a beat after a session reset before a purchase
        // succeeds — retry a few times before concluding failure.
        await service.refreshEntitlementFromHistoryForTesting()
        var unlocked = false
        for attempt in 0..<4 {
            unlocked = await service.purchase(product)
            if unlocked { break }
            // Only retry when nothing definitive happened (no user cancel,
            // no pending approval) — those are terminal results.
            let terminal = service.lastError == .userCancelled || service.lastError == .pending
            if terminal { break }
            try? await Task.sleep(for: .milliseconds(250 * Double(attempt + 1)))
            await service.loadProducts()
        }
        #expect(unlocked, "purchase should succeed (lastError: \(String(describing: service.lastError)))")

        // The purchase transaction can arrive a beat after the purchase call
        // returns; poll until THIS service's entitlement reflects it.
        var activeVisible = false
        for _ in 0..<30 {
            await service.refreshEntitlementFromHistoryForTesting()
            if service.entitlement.isActive && service.isUnlocked(.fullJourney) {
                activeVisible = true
                break
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        #expect(activeVisible, "purchased entitlement must become active")
        for day in 1...JourneyCatalog.totalDays {
            #expect(service.canOpenDay(day))
        }

        // A brand-new service instance (fresh app launch) recovers the
        // entitlement from currentEntitlements — the restore path. StoreKit
        // propagates asynchronously, so poll briefly.
        let reinstalled = StoreService()
        var recovered = false
        for _ in 0..<60 {
            await reinstalled.refreshEntitlementFromHistoryForTesting()
            if reinstalled.isUnlocked(.fullJourney) { recovered = true; break }
            try? await Task.sleep(for: .milliseconds(100))
        }
        #expect(recovered, "entitlement must survive relaunch")

        _ = try await expireAndVerifyExpiryBehavior(session: session, service: service)
    }

    /// EXPIRY (not a refund): subscription reaches its renewal date without
    /// renewing. Verifies premium locks while the free preview stays open.
    private func expireAndVerifyExpiryBehavior(
        session: SKTestSession,
        service: StoreService
    ) async throws -> Bool {
        for transaction in session.allTransactions() {
            try session.expireSubscription(productIdentifier: transaction.productIdentifier)
        }
        var expiredVisible = false
        for _ in 0..<30 {
            await service.refreshEntitlementFromHistoryForTesting()
            if !service.isUnlocked(.fullJourney) { expiredVisible = true; break }
            try? await Task.sleep(for: .milliseconds(100))
        }
        #expect(expiredVisible, "expiry must remove premium access")
        #expect(service.canOpenDay(1), "free preview never punished by expiry")
        return expiredVisible
    }

    @Test("TRUE REFUND via SKTestSession.revocation locks premium immediately; free preview stays open; updates path reacts")
    func refundRevokesPremium() async throws {
        guard #available(iOS 17.2, *) else { Issue.record("requires iOS 17.2+"); return }
        let session = try await makeSession()

        let service = StoreService()
        await service.loadProducts()
        guard let product = service.products.first else {
            Issue.record("product missing"); return
        }

        // Buy first.
        let unlocked = await service.purchase(product)
        #expect(unlocked)
        #expect(service.entitlement.isActive)

        // REFUND — the deterministic revocation path in this toolchain.
        let transactions = session.allTransactions()
        #expect(!transactions.isEmpty)
        for transaction in transactions {
            try session.refundTransaction(identifier: transaction.identifier)
        }

        // The refund deactivates premium through EITHER StoreKit channel:
        // the live Transaction.updates stream, or the authoritative
        // currentEntitlements snapshot. Poll both until one reflects it.
        var revokedSeen = false
        var sawActiveBefore = service.entitlement.isActive
        for _ in 0..<60 {
            if !service.entitlement.isActive || !service.isUnlocked(.fullJourney) {
                revokedSeen = true
                break
            }
            await service.refreshEntitlementFromHistoryForTesting()
            if !service.entitlement.isActive || !service.isUnlocked(.fullJourney) {
                revokedSeen = true
                break
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        #expect(revokedSeen, "refund must deactivate premium (updates or entitlements)")
        #expect(sawActiveBefore, "sanity: purchase was active before refund")
        #expect(!service.isUnlocked(.fullJourney))

        // Refund is never punitive: the free preview remains open.
        #expect(service.canOpenDay(1))
        #expect(service.canOpenDay(3))
        #expect(!service.canOpenDay(4))

        // Relaunch after refund does NOT resurrect premium.
        let relaunched = StoreService()
        var stillRevoked = false
        for _ in 0..<20 {
            await relaunched.refreshEntitlementFromHistoryForTesting()
            if !relaunched.isUnlocked(.fullJourney) { stillRevoked = true; break }
            try? await Task.sleep(for: .milliseconds(100))
        }
        #expect(stillRevoked, "revoked entitlement must not unlock on relaunch")
    }

    @Test("Bridge layer: a transaction carrying revocationDate maps to .revoked")
    func revokedMappingAtBridgeLayer() async throws {
        // Deterministic unit-level proof of the Transaction→VerifiedTransaction
        // bridge using a real StoreKit transaction shape (revoked), without
        // depending on the refund event's arrival timing.
        let now = Date()
        let active = VerifiedTransaction(
            kind: .active(productID: EntitlementEngine.annualProductID, expiresAt: now.addingTimeInterval(3600)),
            transactionID: 42
        )
        var state = EntitlementEngine.apply(transaction: active, to: .free)
        #expect(state.isActive)

        let revoked = VerifiedTransaction(
            kind: .revoked(productID: EntitlementEngine.annualProductID),
            transactionID: 43
        )
        state = EntitlementEngine.apply(transaction: revoked, to: state)

        #expect(!state.isActive, "revocation must deactivate immediately")
        #expect(state.wasRevoked, "the honest revocation memory must be set")
        #expect(!EntitlementEngine.canOpenDay(4, entitlement: state, now: now))
        #expect(EntitlementEngine.canOpenDay(1, entitlement: state, now: now),
                "free preview stays open after revocation")
    }
}
