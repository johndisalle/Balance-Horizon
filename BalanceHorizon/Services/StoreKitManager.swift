// StoreKitManager.swift — Balance Horizon
// StoreKit 2 integration for premium subscriptions and lifetime purchase.
// Supports monthly ($4.99), yearly ($29.99), and lifetime ($79.99) tiers.
// Zero network calls for free tier — StoreKit only activates when user taps Premium.

import Foundation
import StoreKit

/// Use a typealias to disambiguate StoreKit's Transaction from our SwiftData model
typealias StoreTransaction = StoreKit.Transaction

/// Product identifiers — configure these in App Store Connect
enum ProductID {
    static let monthlyPremium = "com.ellasid.balancehorizon.premium.monthly"
    static let yearlyPremium = "com.ellasid.balancehorizon.premium.yearly"
    static let lifetimePremium = "com.ellasid.balancehorizon.premium.lifetime"
    static let allSubscriptions = [monthlyPremium, yearlyPremium]
    static let all = [monthlyPremium, yearlyPremium, lifetimePremium]
}

@Observable
final class StoreKitManager {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isPremium: Bool = false
    var currentTier: PremiumTier = .free
    var isLoading: Bool = false

    private var updateListener: Task<Void, Error>?

    init() {
        updateListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await updatePurchasedProducts() }
    }

    deinit {
        updateListener?.cancel()
    }

    // MARK: - Product Access

    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthlyPremium }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearlyPremium }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == ProductID.lifetimePremium }
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            products = try await Product.products(for: ProductID.all)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedProducts()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in StoreTransaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Entitlement Check

    func updatePurchasedProducts() async {
        var purchasedIDs = Set<String>()
        for await result in StoreTransaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedIDs.insert(transaction.productID)
            } catch {
                continue
            }
        }
        let ids = purchasedIDs
        await MainActor.run {
            self.purchasedProductIDs = ids
            self.isPremium = !ids.isEmpty
            if ids.contains(ProductID.lifetimePremium) {
                self.currentTier = .lifetime
            } else if ids.contains(ProductID.yearlyPremium) {
                self.currentTier = .yearly
            } else if ids.contains(ProductID.monthlyPremium) {
                self.currentTier = .monthly
            } else {
                self.currentTier = .free
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let item):
            return item
        }
    }
}
