// StoreKitManager.swift — Balance Horizon
// StoreKit 2 integration for premium subscriptions.
// Handles product fetching, purchasing, and entitlement verification.
// Zero network calls for free tier — StoreKit only activates when user taps Premium.

import Foundation
import StoreKit
import SwiftData

/// Product identifiers — configure these in App Store Connect
enum ProductID {
    static let monthlyPremium = "com.yourname.balancehorizon.premium.monthly"
    static let yearlyPremium = "com.yourname.balancehorizon.premium.yearly"
    static let all = [monthlyPremium, yearlyPremium]
}

@Observable
final class StoreKitManager {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isPremium: Bool = false

    private var updateListener: Task<Void, Error>?

    init() {
        updateListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await updatePurchasedProducts() }
    }

    deinit {
        updateListener?.cancel()
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

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedProducts()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
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
        var purchased = Set<String>()
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchased.insert(transaction.productID)
            } catch {
                continue
            }
        }
        await MainActor.run {
            self.purchasedProductIDs = purchased
            self.isPremium = !purchased.isEmpty
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
