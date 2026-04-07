// FinanceKitManager.swift — Balance Horizon
// Imports transactions from Apple Wallet via FinanceKit (iOS 17+).
// Guarded with #if canImport so the project still compiles on simulators.

import Foundation
import SwiftData

#if canImport(FinanceKit)
import FinanceKit

@Observable
class FinanceKitManager {

    // MARK: - Properties

    var isAvailable: Bool {
        FinanceStore.isDataAvailable(.financialData)
    }

    var isAuthorized: Bool = false

    var lastSyncDate: Date? {
        get {
            UserDefaults.standard.object(forKey: "financeKitLastSync") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "financeKitLastSync")
        }
    }

    var importedCount: Int = 0

    // MARK: - Authorization

    /// Requests FinanceKit authorization from the user.
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

    /// Fetches new transactions from Apple Wallet and inserts them into SwiftData.
    /// Returns the number of newly imported transactions.
    @discardableResult
    func importTransactions(context: ModelContext) async throws -> Int {
        guard isAvailable, isAuthorized else { return 0 }

        let store = FinanceStore.shared

        // Determine the starting date for the query.
        let since: Date = lastSyncDate ?? Calendar.current.date(byAdding: .day, value: -30, to: .now)!

        let predicate = TransactionQuery(
            sortDescriptors: [SortDescriptor(\FinanceKit.Transaction.transactionDate, order: .reverse)],
            predicate: #Predicate<FinanceKit.Transaction> { tx in
                tx.transactionDate >= since
            }
        )

        let fkTransactions = try await store.transactions(query: predicate)

        // Fetch existing transactions from SwiftData so we can check for duplicates.
        let existingDescriptor = FetchDescriptor<Transaction>()
        let existingTransactions = (try? context.fetch(existingDescriptor)) ?? []

        var count = 0

        for fkTx in fkTransactions {
            let txAmount = fkTx.transactionAmount.amount
            let absAmount = abs(txAmount)
            let txType: TransactionType = txAmount >= 0 ? .income : .expense
            let txDate = fkTx.transactionDate
            let description = fkTx.merchantName
                ?? fkTx.originalTransactionDescription
                ?? "Apple Wallet Transaction"
            let category = categoryFromMCC(fkTx.merchantCategoryCode)

            // Duplicate check: skip if a transaction with the same amount and
            // a date within one day already exists.
            let isDuplicate = existingTransactions.contains { existing in
                abs(existing.amount - absAmount) < 0.01
                    && existing.type == txType
                    && abs(existing.date.timeIntervalSince(txDate)) < 86_400
            }
            guard !isDuplicate else { continue }

            let transaction = Transaction(
                date: txDate,
                amount: absAmount,
                type: txType,
                desc: description,
                category: category,
                isRecurring: false,
                accountID: nil
            )
            context.insert(transaction)
            count += 1
        }

        // Persist and update bookkeeping.
        try context.save()
        lastSyncDate = .now
        importedCount = count

        return count
    }

    // MARK: - MCC Mapping

    /// Maps a Merchant Category Code to an app category string.
    func categoryFromMCC(_ code: Int?) -> String {
        guard let code else { return "General" }
        switch code {
        case 5411, 5412:
            return "Groceries"
        case 5812, 5813, 5814:
            return "Dining"
        case 4111, 4121, 4131, 4784:
            return "Transport"
        case 5691, 5699, 5611:
            return "Shopping"
        case 7832, 7841, 7911, 7922, 7929, 7941:
            return "Entertainment"
        case 8011, 8021, 8031, 8041, 8042, 8049, 8050, 8062, 8071, 8099:
            return "Health"
        case 4900:
            return "Utilities"
        default:
            return "General"
        }
    }
}

#else

// MARK: - Stub for simulators / platforms without FinanceKit

@Observable
class FinanceKitManager {

    var isAvailable: Bool { false }
    var isAuthorized: Bool = false

    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: "financeKitLastSync") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "financeKitLastSync") }
    }

    var importedCount: Int = 0

    func requestAuthorization() async {
        // FinanceKit not available on this platform.
    }

    @discardableResult
    func importTransactions(context: ModelContext) async throws -> Int {
        return 0
    }

    func categoryFromMCC(_ code: Int?) -> String {
        return "General"
    }
}

#endif
