// BalanceHorizonApp.swift — Balance Horizon
// App entry point. Configures SwiftData model container, registers notifications,
// syncs shared data for widgets/watch, and routes between onboarding and main app.

import SwiftUI
import SwiftData

@main
struct BalanceHorizonApp: App {
    @State private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environment(notificationManager)
        }
        .modelContainer(for: [Transaction.self, AppSettings.self, Account.self])
    }
}

/// Root view that checks onboarding state and routes accordingly
struct ContentRootView: View {
    @Query private var settingsArray: [AppSettings]
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Environment(\.modelContext) private var context
    @Environment(NotificationManager.self) private var notificationManager

    private var settings: AppSettings {
        if let existing = settingsArray.first { return existing }
        let new = AppSettings()
        context.insert(new)
        return new
    }

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear { syncSharedData() }
        .onChange(of: transactions.count) { syncSharedData() }
        .task { await setupNotifications() }
    }

    /// Write balances to shared UserDefaults so widgets and watch can read them
    private func syncSharedData() {
        let engine = ProjectionEngine()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let future = cal.date(byAdding: .month, value: 12, to: today)!

        let balances = engine.computeBalances(
            transactions: transactions,
            startingBalance: settings.startingBalance,
            startingDate: settings.startingBalanceDate,
            from: today,
            to: future
        )

        let balanceMap = balances.mapValues { $0.balance }
        SharedDataManager.shared.writeDayBalances(balanceMap)
        if let todayBal = balances[today]?.balance {
            SharedDataManager.shared.writeTodayBalance(todayBal)
        }

        // Process any pending transactions from Apple Watch
        importWatchTransactions()
    }

    private func importWatchTransactions() {
        let pending = SharedDataManager.shared.readAndClearPendingTransactions()
        for dict in pending {
            guard let amount = dict["amount"] as? Double,
                  let typeRaw = dict["type"] as? String,
                  let category = dict["category"] as? String else { continue }
            let type: TransactionType = typeRaw == "Income" ? .income : .expense
            let date: Date
            if let ts = dict["date"] as? TimeInterval {
                date = Date(timeIntervalSince1970: ts)
            } else {
                date = .now
            }
            let tx = Transaction(date: date, amount: amount, type: type, category: category)
            context.insert(tx)
        }
    }

    private func setupNotifications() async {
        guard settings.lowBalanceAlertsEnabled else { return }
        await notificationManager.requestPermission()

        let engine = ProjectionEngine()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let future = cal.date(byAdding: .month, value: 1, to: today)!

        let balances = engine.computeBalances(
            transactions: transactions,
            startingBalance: settings.startingBalance,
            startingDate: settings.startingBalanceDate,
            from: today,
            to: future
        )

        let balanceMap = balances.mapValues { $0.balance }
        notificationManager.scheduleLowBalanceWarnings(
            dayBalances: balanceMap,
            threshold: settings.lowBalanceThreshold
        )
    }
}
