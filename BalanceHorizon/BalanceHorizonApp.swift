// BalanceHorizonApp.swift — Balance Horizon
// App entry point. Configures SwiftData, schedules morning balance notifications,
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
        .modelContainer(for: [Transaction.self, AppSettings.self, Account.self, BudgetGoal.self])
    }
}

/// Root view that checks onboarding state and routes accordingly
struct ContentRootView: View {
    @Query private var settingsArray: [AppSettings]
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Environment(\.modelContext) private var context
    @Environment(NotificationManager.self) private var notificationManager
    @State private var showPaywall = false

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
        .onAppear {
            syncSharedData()
            checkPaywallTrigger()
        }
        .onChange(of: transactions.count) {
            syncSharedData()
            settings.transactionCount = transactions.count
            checkPaywallTrigger()
        }
        .task { await setupNotifications() }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Notifications

    private func setupNotifications() async {
        guard settings.hasCompletedOnboarding else { return }
        await notificationManager.requestPermission()

        // Schedule morning balance notification (the #1 retention driver)
        let engine = ProjectionEngine()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let future = cal.date(byAdding: .month, value: 12, to: today) else { return }

        let balances = engine.computeBalances(
            transactions: transactions,
            startingBalance: settings.startingBalance,
            startingDate: settings.startingBalanceDate,
            from: today,
            to: future
        )

        if let todayBalance = balances[today]?.balance {
            await notificationManager.scheduleMorningBalance(balance: todayBalance)
        }

        // Schedule low-balance warnings if enabled
        if settings.lowBalanceAlertsEnabled {
            let balanceMap = balances.mapValues { $0.balance }
            await notificationManager.scheduleLowBalanceWarnings(
                dayBalances: balanceMap,
                threshold: settings.lowBalanceThreshold
            )
        }
    }

    // MARK: - Shared Data Sync

    private func syncSharedData() {
        let engine = ProjectionEngine()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let future = cal.date(byAdding: .month, value: 12, to: today) else { return }

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

    // MARK: - Smart Paywall Trigger

    /// Show paywall at the right moment:
    /// - After 3 days of use, OR
    /// - After adding 5+ transactions (high engagement = high conversion)
    /// Only if user hasn't seen it yet and isn't already premium
    private func checkPaywallTrigger() {
        guard settings.hasCompletedOnboarding,
              !settings.isPremium,
              !settings.hasSeenPaywall else { return }

        let daysSinceFirstLaunch: Int
        if let firstLaunch = settings.firstLaunchDate {
            daysSinceFirstLaunch = Calendar.current.dateComponents(
                [.day], from: firstLaunch, to: .now
            ).day ?? 0
        } else {
            daysSinceFirstLaunch = 0
        }

        // Trigger after 3 days OR after 5 manually-added transactions
        if daysSinceFirstLaunch >= 3 || settings.transactionCount >= 5 {
            // Small delay so it doesn't feel jarring
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                settings.hasSeenPaywall = true
                showPaywall = true
            }
        }
    }
}
