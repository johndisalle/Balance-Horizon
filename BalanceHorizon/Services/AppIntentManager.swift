// AppIntentManager.swift — Balance Horizon
// Siri Shortcuts using AppIntents framework (iOS 17+).
// Uses SharedDataManager (UserDefaults) to avoid ModelContext Sendable issues.
// Pending transactions are picked up by the main app on next launch.

import AppIntents
import Foundation

// MARK: - Add Expense Intent

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add an expense to Balance Horizon"
    static var description: IntentDescription = IntentDescription("Quickly log an expense transaction.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Category", default: "General")
    var category: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SharedDataManager.shared.writePendingTransaction([
            "amount": amount,
            "type": "Expense",
            "category": category,
            "date": Date.now.timeIntervalSince1970,
            "source": "siri"
        ])

        let formatted = String(format: "$%.2f", amount)
        return .result(dialog: "Added \(formatted) expense for \(category).")
    }
}

// MARK: - Add Income Intent

struct AddIncomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Add income to Balance Horizon"
    static var description: IntentDescription = IntentDescription("Quickly log an income transaction.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Category", default: "General")
    var category: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SharedDataManager.shared.writePendingTransaction([
            "amount": amount,
            "type": "Income",
            "category": category,
            "date": Date.now.timeIntervalSince1970,
            "source": "siri"
        ])

        let formatted = String(format: "$%.2f", amount)
        return .result(dialog: "Added \(formatted) income for \(category).")
    }
}

// MARK: - Check Balance Intent

struct CheckBalanceIntent: AppIntent {
    static var title: LocalizedStringResource = "Check my balance in Balance Horizon"
    static var description: IntentDescription = IntentDescription("See your projected balance for today.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let balance = SharedDataManager.shared.readTodayBalance() ?? 0.0
        let formatted = String(format: "$%.2f", balance)
        return .result(dialog: "Your projected balance today is \(formatted).")
    }
}

// MARK: - App Shortcuts Provider

struct BalanceHorizonShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add expense in \(.applicationName)",
                "Log an expense in \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "minus.circle"
        )
        AppShortcut(
            intent: AddIncomeIntent(),
            phrases: [
                "Add income in \(.applicationName)",
                "Log income in \(.applicationName)"
            ],
            shortTitle: "Add Income",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: CheckBalanceIntent(),
            phrases: [
                "What's my balance in \(.applicationName)",
                "Check my balance in \(.applicationName)"
            ],
            shortTitle: "Check Balance",
            systemImageName: "dollarsign.circle"
        )
    }
}
