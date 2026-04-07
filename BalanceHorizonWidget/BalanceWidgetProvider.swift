import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Configuration Intent

struct BalanceWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Balance Horizon"
    static var description: IntentDescription = "Displays your projected account balance."

    @Parameter(title: "Account Name", default: "Primary")
    var accountName: String
}

// MARK: - Shared Data Keys

private enum SharedDataKeys {
    static let suiteName = "group.com.ellasid.balancehorizon"
    static let dailyBalancesKey = "cached_daily_balances"
    static let lastUpdatedKey = "balances_last_updated"
}

// MARK: - Balance Widget Provider

struct BalanceWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = BalanceWidgetEntry
    typealias Intent = BalanceWidgetIntent

    func placeholder(in context: Context) -> BalanceWidgetEntry {
        BalanceWidgetEntry.placeholder
    }

    func snapshot(for configuration: BalanceWidgetIntent, in context: Context) async -> BalanceWidgetEntry {
        if context.isPreview {
            return BalanceWidgetEntry.placeholder
        }
        return buildEntry()
    }

    func timeline(for configuration: BalanceWidgetIntent, in context: Context) async -> Timeline<BalanceWidgetEntry> {
        let entry = buildEntry()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    // MARK: - Private Helpers

    private func buildEntry() -> BalanceWidgetEntry {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let balanceMap = loadCachedBalances()

        var weekBalances: [WeekDay] = []
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let key = dateKey(for: date)
            let balance = balanceMap[key] ?? 0.0
            weekBalances.append(WeekDay(date: date, balance: balance))
        }

        let todayBalance = weekBalances.first?.balance ?? 0.0
        let tomorrowBalance = weekBalances.count > 1 ? weekBalances[1].balance : todayBalance

        let trend: TrendDirection
        if tomorrowBalance > todayBalance + 0.01 {
            trend = .up
        } else if tomorrowBalance < todayBalance - 0.01 {
            trend = .down
        } else {
            trend = .flat
        }

        return BalanceWidgetEntry(
            date: Date(),
            todayBalance: todayBalance,
            weekBalances: weekBalances,
            trendDirection: trend
        )
    }

    private func loadCachedBalances() -> [String: Double] {
        guard let defaults = UserDefaults(suiteName: SharedDataKeys.suiteName),
              let data = defaults.data(forKey: SharedDataKeys.dailyBalancesKey),
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return sampleBalances()
        }
        return decoded
    }

    private func sampleBalances() -> [String: Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var map: [String: Double] = [:]
        let sampleValues: [Double] = [247.50, 312.00, 185.75, 420.30, 95.00, -12.50, 530.00]
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            map[dateKey(for: date)] = sampleValues[offset]
        }
        return map
    }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
