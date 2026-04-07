// AppIntentManager.swift — Balance Horizon
// Siri Shortcuts using AppIntents framework (iOS 17+).
// Provides intents for adding expenses, adding income, and checking balance.

import AppIntents
import SwiftData
import Foundation

// MARK: - Add Expense Intent

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add an expense to Balance Horizon"
    static var description: IntentDescription = IntentDescription("Quickly log an expense transaction.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Category", default: "General")
    var category: String

    @Parameter(title: "Description", default: "")
    var desc: String

    @Dependency
    var modelContext: ModelContext

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let transaction = Transaction(
            date: .now,
            amount: amount,
            type: .expense,
            desc: desc,
            category: category
        )
        modelContext.insert(transaction)
        try modelContext.save()

        let formatted = String(format: "$%.2f", amount)
        let message = "Added \(formatted) expense for \(category)."
        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - Add Income Intent

struct AddIncomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Add income to Balance Horizon"
    static var description: IntentDescription = IntentDescription("Quickly log an income transaction.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Category", default: "General")
    var category: String

    @Parameter(title: "Description", default: "")
    var desc: String

    @Dependency
    var modelContext: ModelContext

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let transaction = Transaction(
            date: .now,
            amount: amount,
            type: .income,
            desc: desc,
            category: category
        )
        modelContext.insert(transaction)
        try modelContext.save()

        let formatted = String(format: "$%.2f", amount)
        let message = "Added \(formatted) income for \(category)."
        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - Check Balance Intent

struct CheckBalanceIntent: AppIntent {
    static var title: LocalizedStringResource = "Check my balance in Balance Horizon"
    static var description: IntentDescription = IntentDescription("See your projected balance for today.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let defaults = UserDefaults(suiteName: "group.com.yourname.balancehorizon")
        let balance = defaults?.double(forKey: "todayBalance") ?? 0.0
        let formatted = String(format: "$%.2f", balance)
        let message = "Your projected balance today is \(formatted)."
        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - App Shortcuts Provider

struct BalanceHorizonShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add expense in \(.applicationName)",
                "Log an expense in \(.applicationName)",
                "Add a new expense to \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "minus.circle"
        )
        AppShortcut(
            intent: AddIncomeIntent(),
            phrases: [
                "Add income in \(.applicationName)",
                "Log income in \(.applicationName)",
                "Add a new income to \(.applicationName)"
            ],
            shortTitle: "Add Income",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: CheckBalanceIntent(),
            phrases: [
                "What's my balance in \(.applicationName)",
                "Check my balance in \(.applicationName)",
                "Show my balance in \(.applicationName)"
            ],
            shortTitle: "Check Balance",
            systemImageName: "dollarsign.circle"
        )
    }
}
