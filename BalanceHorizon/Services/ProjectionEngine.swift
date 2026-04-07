// ProjectionEngine.swift — Balance Horizon
// Pure rule-based projection engine. Computes running daily balances by:
// 1. Starting from user's initial balance
// 2. Expanding all recurring rules into concrete dated entries
// 3. Summing chronologically to produce a cumulative balance per day
// Zero network calls — fully offline math.

import Foundation
import SwiftData

struct DayBalance: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
    let transactions: [Transaction]
}

@Observable
final class ProjectionEngine {
    private var cache: [Date: DayBalance] = [:]
    private var lastComputeHash: Int = 0

    /// Expand a recurring transaction into concrete instances from its start date up to `horizon`
    static func expandRecurring(_ tx: Transaction, until horizon: Date) -> [(Date, Double)] {
        guard tx.isRecurring, let freq = tx.recurringFrequency else { return [] }
        var results: [(Date, Double)] = []
        var current = tx.date
        let cal = Calendar.current
        let endDate = tx.recurringEndDate ?? horizon

        while current <= min(horizon, endDate) {
            results.append((cal.startOfDay(for: current), tx.signedAmount))
            current = freq.nextDate(after: current)
        }
        return results
    }

    /// Compute daily balances for a date range
    func computeBalances(
        transactions: [Transaction],
        startingBalance: Double,
        startingDate: Date,
        from rangeStart: Date,
        to rangeEnd: Date
    ) -> [Date: DayBalance] {
        let cal = Calendar.current
        let horizon = rangeEnd

        // Build a map of date -> [signed amounts] and date -> [transactions]
        var dailyAmounts: [Date: Double] = [:]
        var dailyTransactions: [Date: [Transaction]] = [:]

        for tx in transactions {
            if tx.isRecurring {
                let instances = Self.expandRecurring(tx, until: horizon)
                for (date, amount) in instances {
                    let day = cal.startOfDay(for: date)
                    if day >= cal.startOfDay(for: startingDate) {
                        dailyAmounts[day, default: 0] += amount
                        dailyTransactions[day, default: []].append(tx)
                    }
                }
            } else {
                let day = cal.startOfDay(for: tx.date)
                if day >= cal.startOfDay(for: startingDate) {
                    dailyAmounts[day, default: 0] += tx.signedAmount
                    dailyTransactions[day, default: []].append(tx)
                }
            }
        }

        // Walk day-by-day from startingDate to rangeEnd computing cumulative balance
        var result: [Date: DayBalance] = [:]
        var balance = startingBalance
        var current = cal.startOfDay(for: startingDate)
        let end = cal.startOfDay(for: rangeEnd)

        while current <= end {
            let dayAmount = dailyAmounts[current] ?? 0
            balance += dayAmount
            let start = cal.startOfDay(for: rangeStart)
            if current >= start {
                result[current] = DayBalance(
                    date: current,
                    balance: balance,
                    transactions: dailyTransactions[current] ?? []
                )
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return result
    }
}
