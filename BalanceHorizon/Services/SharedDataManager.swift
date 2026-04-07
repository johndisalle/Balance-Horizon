// SharedDataManager.swift — Balance Horizon
// Manages shared data between the main app, widget extension, and watchOS companion.

import Foundation

class SharedDataManager {

    static let shared = SharedDataManager()
    static let suiteName = "group.com.ellasid.balancehorizon"

    private let defaults: UserDefaults

    private init() {
        defaults = UserDefaults(suiteName: SharedDataManager.suiteName) ?? UserDefaults.standard
    }

    // MARK: - Keys

    private enum Keys {
        static let dayBalances = "dayBalances"
        static let todayBalance = "todayBalance"
        static let pendingWatchTransactions = "pendingWatchTransactions"
    }

    // MARK: - Date Formatter

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    // MARK: - Day Balances

    /// Writes a date-to-balance mapping into shared UserDefaults.
    /// Encoded as an array of dictionaries with "date" (timeIntervalSince1970) and "balance" keys.
    func writeDayBalances(_ balances: [Date: Double]) {
        let encoded: [[String: Any]] = balances.map { (date, balance) in
            [
                "date": date.timeIntervalSince1970,
                "balance": balance
            ]
        }
        defaults.set(encoded, forKey: Keys.dayBalances)
    }

    /// Reads the date-to-balance mapping from shared UserDefaults.
    func readDayBalances() -> [Date: Double] {
        guard let stored = defaults.array(forKey: Keys.dayBalances) as? [[String: Any]] else {
            return [:]
        }

        var result: [Date: Double] = [:]
        for entry in stored {
            if let timestamp = entry["date"] as? Double,
               let balance = entry["balance"] as? Double {
                let date = Date(timeIntervalSince1970: timestamp)
                result[date] = balance
            }
        }
        return result
    }

    // MARK: - Today Balance

    /// Writes today's balance to shared UserDefaults for quick widget access.
    func writeTodayBalance(_ balance: Double) {
        defaults.set(balance, forKey: Keys.todayBalance)
    }

    /// Reads today's balance from shared UserDefaults.
    func readTodayBalance() -> Double? {
        guard defaults.object(forKey: Keys.todayBalance) != nil else {
            return nil
        }
        return defaults.double(forKey: Keys.todayBalance)
    }

    // MARK: - Pending Watch Transactions

    /// Appends a transaction dictionary to the pending watch transactions queue.
    func writePendingTransaction(_ dict: [String: Any]) {
        var existing = defaults.array(forKey: Keys.pendingWatchTransactions) as? [[String: Any]] ?? []
        existing.append(dict)
        defaults.set(existing, forKey: Keys.pendingWatchTransactions)
    }

    /// Reads all pending watch transactions and clears the queue.
    func readAndClearPendingTransactions() -> [[String: Any]] {
        let transactions = defaults.array(forKey: Keys.pendingWatchTransactions) as? [[String: Any]] ?? []
        defaults.removeObject(forKey: Keys.pendingWatchTransactions)
        return transactions
    }
}
