// FinanceKitManager.swift — Balance Horizon
// Imports transactions from Apple Wallet via FinanceKit (iOS 17.4+).
// Guarded with #if canImport so the project compiles on simulators.

import Foundation
import SwiftData

#if canImport(FinanceKit)
import FinanceKit

@available(iOS 17.4, *)
@Observable
class FinanceKitManagerImpl {

    // MARK: - Properties

    var isAvailable: Bool {
        FinanceStore.isDataAvailable(.financialData)
    }

    var isAuthorized: Bool = false

    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: "financeKitLastSync") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "financeKitLastSync") }
    }

    var importedCount: Int = 0

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            let status = try await FinanceStore.shared.requestAuthorization()
            isAuthorized = (status == .authorized)
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - Import

    @discardableResult
    func importTransactions(context: ModelContext) async throws -> Int {
        guard isAvailable, isAuthorized else { return 0 }

        let store = FinanceStore.shared
        let since = lastSyncDate ?? Calendar.current.date(byAdding: .day, value: -30, to: .now)!

        let query = TransactionQuery(
            sortDescriptors: [SortDescriptor(\FinanceKit.Transaction.transactionDate, order: .reverse)],
            predicate: #Predicate<FinanceKit.Transaction> { tx in
                tx.transactionDate >= since
            }
        )

        let fkTransactions = try await store.transactions(query: query)

        let existingDescriptor = FetchDescriptor<Transaction>()
        let existingTransactions = (try? context.fetch(existingDescriptor)) ?? []

        var count = 0

        for fkTx in fkTransactions {
            let decimalAmount = fkTx.transactionAmount.amount
            let doubleAmount = NSDecimalNumber(decimal: decimalAmount).doubleValue
            let absAmount = abs(doubleAmount)
            let txType: TransactionType = doubleAmount >= 0 ? .income : .expense
            let txDate = fkTx.transactionDate

            let description: String
            if let merchant = fkTx.merchantName {
                description = merchant
            } else {
                let original = fkTx.originalTransactionDescription
                description = original.isEmpty ? "Apple Wallet" : original
            }

            let mccValue = fkTx.merchantCategoryCode.flatMap { Int($0.rawValue) }
            let category = Self.categoryFromMCC(mccValue)

            // Duplicate check
            let isDupe = existingTransactions.contains { existing in
                let amountMatch = abs(existing.amount - absAmount) < 0.01
                let typeMatch = existing.type == txType
                let dateMatch = abs(existing.date.timeIntervalSince(txDate)) < 86_400
                return amountMatch && typeMatch && dateMatch
            }
            guard !isDupe else { continue }

            let transaction = Transaction(
                date: txDate,
                amount: absAmount,
                type: txType,
                desc: description,
                category: category
            )
            context.insert(transaction)
            count += 1
        }

        try context.save()
        lastSyncDate = .now
        importedCount = count
        return count
    }

    // MARK: - MCC Mapping

    static func categoryFromMCC(_ code: Int?) -> String {
        guard let code else { return "General" }
        switch code {
        case 5411, 5412: return "Groceries"
        case 5812, 5813, 5814: return "Dining"
        case 4111, 4121, 4131, 4784: return "Transport"
        case 5691, 5699, 5611: return "Shopping"
        case 7832, 7841, 7911, 7922, 7929, 7941: return "Entertainment"
        case 8011, 8021, 8031, 8041, 8042, 8049, 8050, 8062, 8071, 8099: return "Health"
        case 4900: return "Utilities"
        default: return "General"
        }
    }
}
#endif

// MARK: - Unified wrapper that works on all iOS versions

@Observable
class FinanceKitManager {

    var isAvailable: Bool = false
    var isAuthorized: Bool = false
    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: "financeKitLastSync") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "financeKitLastSync") }
    }
    var importedCount: Int = 0

    #if canImport(FinanceKit)
    private var impl: Any? = nil

    init() {
        if #available(iOS 17.4, *) {
            let manager = FinanceKitManagerImpl()
            impl = manager
            isAvailable = manager.isAvailable
        }
    }
    #else
    init() {}
    #endif

    func requestAuthorization() async {
        #if canImport(FinanceKit)
        if #available(iOS 17.4, *), let manager = impl as? FinanceKitManagerImpl {
            await manager.requestAuthorization()
            isAuthorized = manager.isAuthorized
        }
        #endif
    }

    @discardableResult
    func importTransactions(context: ModelContext) async throws -> Int {
        #if canImport(FinanceKit)
        if #available(iOS 17.4, *), let manager = impl as? FinanceKitManagerImpl {
            let count = try await manager.importTransactions(context: context)
            importedCount = manager.importedCount
            lastSyncDate = manager.lastSyncDate
            return count
        }
        #endif
        return 0
    }
}
