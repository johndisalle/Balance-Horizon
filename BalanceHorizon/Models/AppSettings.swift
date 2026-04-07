// AppSettings.swift — Balance Horizon
// Persists user preferences: starting balance, categories, onboarding state,
// notification preferences, and premium tier.

import Foundation
import SwiftData

enum PremiumTier: String, Codable {
    case free = "Free"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case lifetime = "Lifetime"

    var isPremium: Bool { self != .free }
}

@Model
final class AppSettings {
    var id: UUID
    var startingBalance: Double
    var startingBalanceDate: Date
    var hasCompletedOnboarding: Bool
    var categories: [String]
    var isPremium: Bool
    var premiumTier: PremiumTier

    // Notification preferences
    var lowBalanceAlertsEnabled: Bool
    var lowBalanceThreshold: Double
    var dailyReminderEnabled: Bool

    // Paywall timing
    var firstLaunchDate: Date?
    var transactionCount: Int
    var hasSeenPaywall: Bool

    init() {
        self.id = UUID()
        self.startingBalance = 0
        self.startingBalanceDate = Calendar.current.startOfDay(for: .now)
        self.hasCompletedOnboarding = false
        self.categories = Self.defaultCategories
        self.isPremium = false
        self.premiumTier = .free
        self.lowBalanceAlertsEnabled = true
        self.lowBalanceThreshold = 100
        self.dailyReminderEnabled = false
        self.firstLaunchDate = nil
        self.transactionCount = 0
        self.hasSeenPaywall = false
    }

    static let defaultCategories = [
        "Salary", "Rent", "Groceries", "Utilities", "Transport",
        "Dining", "Entertainment", "Health", "Shopping", "Subscriptions",
        "Savings", "Gifts", "Education", "Travel", "General"
    ]
}
