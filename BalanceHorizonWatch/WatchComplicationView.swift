import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct BalanceTimelineProvider: TimelineProvider {
    private let sharedDefaults = UserDefaults(suiteName: "group.com.yourname.balancehorizon")

    func placeholder(in context: Context) -> BalanceEntry {
        BalanceEntry(date: Date(), balance: 1250, previousBalance: 1200)
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        let entry = currentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let entry = currentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentEntry() -> BalanceEntry {
        let balance = sharedDefaults?.double(forKey: "todayBalance") ?? 0.0
        let previousBalance = sharedDefaults?.double(forKey: "yesterdayBalance") ?? 0.0
        return BalanceEntry(date: Date(), balance: balance, previousBalance: previousBalance)
    }
}

// MARK: - Timeline Entry

struct BalanceEntry: TimelineEntry {
    let date: Date
    let balance: Double
    let previousBalance: Double

    var trendArrow: String {
        if balance > previousBalance {
            return "arrow.up.right"
        } else if balance < previousBalance {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }
}

// MARK: - Accessory Circular

struct AccessoryCircularView: View {
    let entry: BalanceEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text(shortCurrency(entry.balance))
                .font(.system(.body, design: .rounded).bold())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .widgetAccentable()
        }
    }
}

// MARK: - Accessory Rectangular

struct AccessoryRectangularView: View {
    let entry: BalanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Balance")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.secondary)
                .widgetAccentable()

            HStack(spacing: 4) {
                Text(formatCurrency(entry.balance))
                    .font(.system(.headline, design: .rounded).bold())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Image(systemName: entry.trendArrow)
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundColor(trendColor(entry))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func trendColor(_ entry: BalanceEntry) -> Color {
        if entry.balance > entry.previousBalance {
            return .green
        } else if entry.balance < entry.previousBalance {
            return .red
        } else {
            return .secondary
        }
    }
}

// MARK: - Accessory Inline

struct AccessoryInlineView: View {
    let entry: BalanceEntry

    var body: some View {
        Text("Balance: \(formatCurrency(entry.balance))")
            .font(.system(.body, design: .rounded))
    }
}

// MARK: - Widget Configuration

struct BalanceComplicationWidget: Widget {
    let kind: String = "BalanceComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BalanceTimelineProvider()) { entry in
            BalanceComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Balance")
        .description("Shows your current balance at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Entry View Router

struct BalanceComplicationEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: BalanceEntry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            AccessoryCircularView(entry: entry)
        }
    }
}

// MARK: - Currency Helpers

private func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "$0"
}

private func shortCurrency(_ value: Double) -> String {
    let absValue = abs(value)
    let sign = value < 0 ? "-" : ""
    if absValue >= 1_000_000 {
        return "\(sign)$\(String(format: "%.1fM", absValue / 1_000_000))"
    } else if absValue >= 1_000 {
        return "\(sign)$\(String(format: "%.0fK", absValue / 1_000))"
    } else {
        return "\(sign)$\(String(format: "%.0f", absValue))"
    }
}

// NOTE: To use complications, create a separate watchOS Widget Extension target
// and use this as the @main entry point in that target:
//
// @main
// struct BalanceHorizonWidgetBundle: WidgetBundle {
//     var body: some Widget {
//         BalanceComplicationWidget()
//     }
// }
