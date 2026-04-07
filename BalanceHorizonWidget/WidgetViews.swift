import SwiftUI
import WidgetKit

// MARK: - Currency Formatter

private let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter
}()

private let compactCurrencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    formatter.maximumFractionDigits = 0
    formatter.minimumFractionDigits = 0
    return formatter
}()

// MARK: - Balance Color

private func balanceColor(for amount: Double) -> Color {
    if amount >= 100 {
        return .green
    } else if amount >= 0 {
        return .orange
    } else {
        return .red
    }
}

// MARK: - Date Formatters

private let todayDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMM d"
    return formatter
}()

// MARK: - Small Balance Widget View

struct SmallBalanceWidgetView: View {
    let entry: BalanceWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("Balance Horizon")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(todayDateFormatter.string(from: entry.date))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(currencyFormatter.string(from: NSNumber(value: entry.todayBalance)) ?? "$0.00")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(balanceColor(for: entry.todayBalance))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Image(systemName: entry.trendDirection.symbolName)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(trendColor)
            }

            Text("Today's Balance")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(URL(string: "balancehorizon://today"))
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private var trendColor: Color {
        switch entry.trendDirection {
        case .up: return .green
        case .down: return .red
        case .flat: return .secondary
        }
    }
}

// MARK: - Medium Balance Widget View

struct MediumBalanceWidgetView: View {
    let entry: BalanceWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("Balance Horizon")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("7-Day Forecast")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 2)

            HStack(spacing: 0) {
                ForEach(Array(entry.weekBalances.prefix(7).enumerated()), id: \.offset) { index, day in
                    if index > 0 {
                        Spacer(minLength: 2)
                    }
                    dayColumn(day: day)
                    if index < min(entry.weekBalances.count, 7) - 1 {
                        Spacer(minLength: 2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(URL(string: "balancehorizon://today"))
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    @ViewBuilder
    private func dayColumn(day: WeekDay) -> some View {
        VStack(spacing: 4) {
            Text(day.dayAbbreviation.prefix(3).uppercased())
                .font(.system(size: 9, weight: day.isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(day.isToday ? .primary : .secondary)

            RoundedRectangle(cornerRadius: 6)
                .fill(balanceColor(for: day.balance).opacity(day.isToday ? 0.2 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            day.isToday ? balanceColor(for: day.balance) : .clear,
                            lineWidth: 1.5
                        )
                )
                .frame(height: 44)
                .overlay(
                    VStack(spacing: 1) {
                        Text(compactCurrencyFormatter.string(from: NSNumber(value: day.balance)) ?? "$0")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(balanceColor(for: day.balance))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                )

            if day.isToday {
                Circle()
                    .fill(balanceColor(for: day.balance))
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    BalanceWidget()
} timeline: {
    BalanceWidgetEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    WeekBalanceWidget()
} timeline: {
    BalanceWidgetEntry.placeholder
}
