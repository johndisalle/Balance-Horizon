// Transaction.swift — Balance Horizon
// Core data model for all financial transactions (one-time and recurring).
// Uses SwiftData for iOS 17+ offline-first persistence.

import Foundation
import SwiftData

/// Frequency options for recurring transactions
enum RecurringFrequency: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    var id: String { rawValue }

    /// Returns the next date after `from` based on frequency
    func nextDate(after from: Date) -> Date {
        let cal = Calendar.current
        switch self {
        case .daily:    return cal.date(byAdding: .day, value: 1, to: from)!
        case .weekly:   return cal.date(byAdding: .weekOfYear, value: 1, to: from)!
        case .biweekly: return cal.date(byAdding: .weekOfYear, value: 2, to: from)!
        case .monthly:  return cal.date(byAdding: .month, value: 1, to: from)!
        case .quarterly:return cal.date(byAdding: .month, value: 3, to: from)!
        case .yearly:   return cal.date(byAdding: .year, value: 1, to: from)!
        }
    }
}

/// Transaction type: income adds, expense subtracts
enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case income = "Income"
    case expense = "Expense"
    var id: String { rawValue }
}

@Model
final class Transaction {
    var id: UUID
    var date: Date
    var amount: Double
    var type: TransactionType
    var desc: String
    var category: String
    var isRecurring: Bool
    var recurringFrequency: RecurringFrequency?
    var recurringEndDate: Date?
    /// Links generated instances back to the parent recurring rule
    var recurringParentID: UUID?
    var createdAt: Date

    init(
        date: Date = .now,
        amount: Double = 0,
        type: TransactionType = .expense,
        desc: String = "",
        category: String = "General",
        isRecurring: Bool = false,
        recurringFrequency: RecurringFrequency? = nil,
        recurringEndDate: Date? = nil,
        recurringParentID: UUID? = nil
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.amount = amount
        self.type = type
        self.desc = desc
        self.category = category
        self.isRecurring = isRecurring
        self.recurringFrequency = recurringFrequency
        self.recurringEndDate = recurringEndDate
        self.recurringParentID = recurringParentID
        self.createdAt = .now
    }

    /// Signed amount: positive for income, negative for expense
    var signedAmount: Double {
        type == .income ? amount : -amount
    }
}
