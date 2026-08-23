import Foundation
import StoreKit

// MARK: - StoreService
//
// StoreKit 2 wrapper. Responsibilities: load products, purchase, restore,
// observe transaction updates, and translate everything into the pure
// EntitlementState via EntitlementEngine. No StoreKit types escape this file.

@MainActor
@Observable
final class StoreService {

    // MARK: Observable state

    private(set) var products: [Product] = []
    private(set) var entitlement = EntitlementState.free
    private(set) var isLoading = false
    private(set) var lastError: StoreError?
    /// Set ONLY after an explicit user restore finds no prior purchase —
    /// never as a side effect of a failed product fetch.
    private(set) var restoreFoundNothing = false
    /// Set briefly when a purchase completes, for a quiet confirmation.
    private(set) var purchaseCompleted = false

    nonisolated enum StoreError: Equatable, Sendable {
        case unavailable          // StoreKit not usable (simulator quirks, parental controls)
        case productNotFound
        case userCancelled
        case pending             // approval required (Ask to Buy)
        case failed
    }

    // MARK: Wiring

    /// Injectable for tests: production uses StoreKit itself.
    private let engine: any StoreEngine
    private var updatesTask: Task<Void, Never>?

    init(engine: (any StoreEngine)? = nil) {
        self.engine = engine ?? LiveStoreEngine()
        // On launch: recover whatever App Store already knows FIRST (the
        // history refresh terminates), THEN enter the infinite observation
        // loop. Order matters — observeTransactions never returns.
        updatesTask = Task { [weak self] in
            await self?.refreshEntitlementFromHistory()
            await self?.observeTransactions()
        }
    }

    deinit {
        MainActor.assumeIsolated {
            updatesTask?.cancel()
        }
    }

    // MARK: Products

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await engine.products(for: [EntitlementEngine.annualProductID])
            products = loaded
            if loaded.isEmpty { lastError = .productNotFound }
        } catch {
            lastError = .unavailable
        }
    }

    // MARK: Purchase

    /// Returns true when the purchase resulted in an active entitlement.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        lastError = nil
        do {
            let result = try await engine.purchase(product)
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    entitlement = EntitlementEngine.apply(
                        transaction: transaction.emberTransaction,
                        to: entitlement
                    )
                    await transaction.finish()
                    purchaseCompleted = true
                    return entitlement.isActive
                case .unverified:
                    lastError = .failed
                    return false
                }
            case .userCancelled:
                lastError = .userCancelled
                return false
            case .pending:
                lastError = .pending
                return false
            @unknown default:
                lastError = .failed
                return false
            }
        } catch {
            lastError = .failed
            return false
        }
    }

    // MARK: Restore

    /// App Store restore. Always honest: if nothing to restore, the UI says so.
    func restore() async {
        lastError = nil
        restoreFoundNothing = false
        do {
            try await engine.restore()
            await refreshEntitlementFromHistory()
            if !entitlement.isActive { restoreFoundNothing = true }
        } catch {
            lastError = .failed
        }
    }

    // MARK: Transaction observation

    private func observeTransactions() async {
        for await update in engine.transactionUpdates() {
            if case .verified(let transaction) = update {
                entitlement = EntitlementEngine.apply(
                    transaction: transaction.emberTransaction,
                    to: entitlement
                )
                await transaction.finish()
            }
        }
    }

    private func refreshEntitlementFromHistory() async {
        // Current entitlements (renewals included) are the source of truth.
        var next = EntitlementState.free
        for await item in await engine.currentEntitlements() {
            if case .verified(let transaction) = item {
                next = EntitlementEngine.apply(transaction: transaction.emberTransaction, to: next)
            }
        }
        // Preserve revocation memory only if nothing active replaced it.
        if !next.isActive && entitlement.wasRevoked {
            next.wasRevoked = true
        }
        entitlement = next
    }

    // MARK: Gates (single entry point for features)

    func canOpenDay(_ dayNumber: Int, now: Date = .now) -> Bool {
        EntitlementEngine.canOpenDay(dayNumber, entitlement: entitlement, now: now)
    }

    func isUnlocked(_ feature: PremiumFeature, now: Date = .now) -> Bool {
        EntitlementEngine.isUnlocked(feature, in: entitlement, now: now)
    }

    /// Clears the transient purchase-completed flag (UI consumes it).
    func consumePurchaseConfirmation() {
        purchaseCompleted = false
    }

    /// Test support: re-reads current entitlements from StoreKit.
    func refreshEntitlementFromHistoryForTesting() async {
        await refreshEntitlementFromHistory()
    }
}

// MARK: - Engine seam (test double boundary)

nonisolated protocol StoreEngine: Sendable {
    func products(for ids: [String]) async throws -> [Product]
    func purchase(_ product: Product) async throws -> Product.PurchaseResult
    func restore() async throws
    func transactionUpdates() -> Transaction.Transactions
    func currentEntitlements() async -> Transaction.Transactions
}

/// Production engine — straight StoreKit 2.
nonisolated struct LiveStoreEngine: StoreEngine {
    func products(for ids: [String]) async throws -> [Product] {
        try await Product.products(for: ids)
    }
    func purchase(_ product: Product) async throws -> Product.PurchaseResult {
        try await product.purchase()
    }
    func restore() async throws {
        try await AppStore.sync()
    }
    func transactionUpdates() -> Transaction.Transactions {
        Transaction.updates
    }
    func currentEntitlements() async -> Transaction.Transactions {
        await Transaction.currentEntitlements
    }
}

// MARK: - Bridging StoreKit transactions into the pure model

nonisolated extension Transaction {
    var emberTransaction: VerifiedTransaction {
        // A revocation (refund, family-sharing loss) must deactivate
        // immediately — it wins over any expiry math.
        if revocationDate != nil {
            return VerifiedTransaction(
                kind: .revoked(productID: productID),
                transactionID: id
            )
        }
        if let expiration = expirationDate {
            return VerifiedTransaction(
                kind: .active(productID: productID, expiresAt: expiration),
                transactionID: id
            )
        }
        // Non-expiring (lifetime) purchases still count as active.
        return VerifiedTransaction(
            kind: .active(productID: productID, expiresAt: nil),
            transactionID: id
        )
    }
}
