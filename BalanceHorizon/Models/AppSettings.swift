// AppSettings.swift — Balance Horizon
// Persists user preferences: starting balance, categories, onboarding state.
// Uses SwiftData as a single-row settings store.

import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var startingBalance: Double
    var startingBalanceDate: Date
    var hasCompletedOnboarding: Bool
    var categories: [String]
    var isPremium: Bool

    init() {
        self.id = UUID()
        self.startingBalance = 0
        self.startingBalanceDate = Calendar.current.startOfDay(for: .now)
        self.hasCompletedOnboarding = false
        self.categories = Self.defaultCategories
        self.isPremium = false
    }

    static let defaultCategories = [
        "Salary", "Rent", "Groceries", "Utilities", "Transport",
        "Dining", "Entertainment", "Health", "Shopping", "Subscriptions",
        "Savings", "Gifts", "Education", "Travel", "General"
    ]
}
