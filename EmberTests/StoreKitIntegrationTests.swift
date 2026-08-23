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

@MainActor
@Suite("StoreKit integration (local config)")
struct StoreKitIntegrationTests {

    @available(iOS 17.2, *)
    private func makeSession() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "EmberStoreKitTest")
        session.disableDialogs = true
        session.clearTransactions()
        return session
    }

    @Test("Products load through the live engine via local configuration")
    func productsLoad() async throws {
        guard #available(iOS 17.2, *) else { Issue.record("requires iOS 17.2+"); return }
        _ = try makeSession()

        let service = StoreService()
        await service.loadProducts()

        #expect(service.lastError == nil)
        #expect(service.products.count == 1)
        #expect(service.products.first?.id == EntitlementEngine.annualProductID)
        #expect(service.products.first?.displayPrice.isEmpty == false)
    }

    @Test("Purchase unlocks every premium day; entitlement survives reload")
    func purchaseFlow() async throws {
        guard #available(iOS 17.2, *) else { Issue.record("requires iOS 17.2+"); return }
        let session = try makeSession()

        let service = StoreService()
        await service.loadProducts()
        guard let product = service.products.first else {
            Issue.record("product missing"); return
        }

        let unlocked = await service.purchase(product)
        #expect(unlocked)
        #expect(service.entitlement.isActive)
        for day in 1...JourneyCatalog.totalDays {
            #expect(service.canOpenDay(day))
        }

        // A brand-new service instance (fresh app launch) recovers the
        // entitlement from currentEntitlements — the restore path. StoreKit
        // propagates asynchronously, so poll briefly.
        let reinstalled = StoreService()
        var recovered = false
        for _ in 0..<30 {
            await reinstalled.refreshEntitlementFromHistoryForTesting()
            if reinstalled.isUnlocked(.fullJourney) { recovered = true; break }
            try? await Task.sleep(for: .milliseconds(100))
        }
        #expect(recovered, "entitlement must survive relaunch")

        // Refund revokes access but keeps the free preview open.
        for transaction in session.allTransactions() {
            try session.expireSubscription(productIdentifier: transaction.productIdentifier)
        }
        var revokedVisible = false
        for _ in 0..<30 {
            await service.refreshEntitlementFromHistoryForTesting()
            if !service.isUnlocked(.fullJourney) { revokedVisible = true; break }
            try? await Task.sleep(for: .milliseconds(100))
        }
        #expect(revokedVisible, "expiration must remove premium access")
        #expect(service.canOpenDay(1), "free preview never punished")
    }
}
