import WidgetKit
import SwiftUI

// MARK: - Widget Bundle

@main
struct BalanceHorizonWidgetBundle: WidgetBundle {
    var body: some Widget {
        BalanceWidget()
        WeekBalanceWidget()
        ForecastGraphWidget()
    }
}

// MARK: - Small Balance Widget

struct BalanceWidget: Widget {
    let kind: String = "BalanceWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: BalanceWidgetIntent.self,
            provider: BalanceWidgetProvider()
        ) { entry in
            SmallBalanceWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Balance")
        .description("See your projected balance for today at a glance.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

// MARK: - Medium Week Balance Widget

struct WeekBalanceWidget: Widget {
    let kind: String = "WeekBalanceWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: BalanceWidgetIntent.self,
            provider: BalanceWidgetProvider()
        ) { entry in
            MediumBalanceWidgetView(entry: entry)
        }
        .configurationDisplayName("7-Day Forecast")
        .description("View your projected balance for the next 7 days.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Forecast Graph Widget

struct ForecastGraphWidget: Widget {
    let kind: String = "ForecastGraphWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: ForecastGraphProvider()
        ) { entry in
            ForecastGraphEntryView(entry: entry)
        }
        .configurationDisplayName("Balance Graph")
        .description("A beautiful 7-day balance trend line chart.")
        .supportedFamilies([.systemMedium, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

// MARK: - Forecast Graph Entry View (family dispatcher)

struct ForecastGraphEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BalanceWidgetEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            AccessoryRectangularGraphView(entry: entry)
        default:
            GraphWidgetView(entry: entry)
        }
    }
}

// MARK: - Forecast Graph Static Provider

struct ForecastGraphProvider: TimelineProvider {
    typealias Entry = BalanceWidgetEntry

    func placeholder(in context: Context) -> BalanceWidgetEntry {
        BalanceWidgetEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceWidgetEntry) -> Void) {
        if context.isPreview {
            completion(BalanceWidgetEntry.placeholder)
        } else {
            completion(ForecastGraphDataBuilder.buildEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceWidgetEntry>) -> Void) {
        let entry = ForecastGraphDataBuilder.buildEntry()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

// MARK: - Shared Data Builder for Static Provider

enum ForecastGraphDataBuilder {
    private static let suiteName = "group.com.yourname.balancehorizon"
    private static let dailyBalancesKey = "cached_daily_balances"

    static func buildEntry() -> BalanceWidgetEntry {
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
        let lastBalance = weekBalances.last?.balance ?? todayBalance

        let trend: TrendDirection
        if lastBalance > todayBalance + 0.01 {
            trend = .up
        } else if lastBalance < todayBalance - 0.01 {
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

    private static func loadCachedBalances() -> [String: Double] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: dailyBalancesKey),
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return sampleBalances()
        }
        return decoded
    }

    private static func sampleBalances() -> [String: Double] {
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

    private static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
