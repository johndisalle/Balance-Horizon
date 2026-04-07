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

// MARK: - Graph Widget View (systemMedium)

struct GraphWidgetView: View {
    let entry: BalanceWidgetEntry

    private var balances: [Double] {
        entry.weekBalances.prefix(7).map(\.balance)
    }

    private var trendColor: Color {
        guard let first = balances.first, let last = balances.last else { return .blue }
        if last > first + 0.01 { return .green }
        if last < first - 0.01 { return .red }
        return .blue
    }

    private var trendArrow: String {
        guard let first = balances.first, let last = balances.last else { return "arrow.right" }
        if last > first + 0.01 { return "arrow.up.right" }
        if last < first - 0.01 { return "arrow.down.right" }
        return "arrow.right"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(compactCurrencyFormatter.string(from: NSNumber(value: entry.todayBalance)) ?? "$0")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(trendColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Text("Today's Balance")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: trendArrow)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(trendColor)
                    Text("7-Day Forecast")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 4)

            // Chart area
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height - 16 // reserve space for day labels

                ZStack(alignment: .bottom) {
                    // Gradient fill under the line
                    SmoothLineShape(values: balances, in: CGSize(width: width, height: height), closed: true)
                        .fill(
                            LinearGradient(
                                colors: [trendColor.opacity(0.35), trendColor.opacity(0.08), trendColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: height)

                    // The line itself
                    SmoothLineShape(values: balances, in: CGSize(width: width, height: height), closed: false)
                        .stroke(
                            LinearGradient(
                                colors: [trendColor.opacity(0.9), trendColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                        .frame(height: height)

                    // Data point dots
                    PointDotsView(values: balances, size: CGSize(width: width, height: height), color: trendColor)
                        .frame(height: height)

                    // Day labels at the bottom
                    HStack(spacing: 0) {
                        ForEach(Array(entry.weekBalances.prefix(7).enumerated()), id: \.offset) { _, day in
                            Text(day.dayAbbreviation.prefix(3).uppercased())
                                .font(.system(size: 8, weight: .medium, design: .rounded))
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 14)
                    .offset(y: 8)
                }
            }

            // Footer
            HStack {
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 7, weight: .semibold, design: .rounded))
                        .foregroundStyle(.quaternary)
                    Text("Balance Horizon")
                        .font(.system(size: 7, weight: .semibold, design: .rounded))
                        .foregroundStyle(.quaternary)
                }
            }
            .padding(.top, 2)
        }
        .widgetURL(URL(string: "balancehorizon://today"))
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Accessory Rectangular Graph View (Lock Screen Sparkline)

struct AccessoryRectangularGraphView: View {
    let entry: BalanceWidgetEntry

    private var balances: [Double] {
        entry.weekBalances.prefix(7).map(\.balance)
    }

    var body: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Balance")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(compactCurrencyFormatter.string(from: NSNumber(value: entry.todayBalance)) ?? "$0")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(width: 52, alignment: .leading)

            GeometryReader { geometry in
                SmoothLineShape(
                    values: balances,
                    in: CGSize(width: geometry.size.width, height: geometry.size.height),
                    closed: false
                )
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
        .widgetURL(URL(string: "balancehorizon://today"))
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
    }
}

// MARK: - Smooth Line Shape (Quadratic Bezier)

struct SmoothLineShape: Shape {
    let values: [Double]
    let chartSize: CGSize
    let closed: Bool

    init(values: [Double], in size: CGSize, closed: Bool) {
        self.values = values
        self.chartSize = size
        self.closed = closed
    }

    func path(in rect: CGRect) -> Path {
        guard values.count >= 2 else { return Path() }

        let minVal = (values.min() ?? 0)
        let maxVal = (values.max() ?? 1)
        let range = maxVal - minVal
        let safeRange = range < 0.01 ? 1.0 : range

        // Add 10% vertical padding so the line doesn't touch edges
        let verticalPadding: CGFloat = rect.height * 0.1
        let drawHeight = rect.height - verticalPadding * 2

        let stepX = rect.width / CGFloat(values.count - 1)

        func point(at index: Int) -> CGPoint {
            let x = CGFloat(index) * stepX
            let normalized = CGFloat((values[index] - minVal) / safeRange)
            let y = rect.height - verticalPadding - normalized * drawHeight
            return CGPoint(x: x, y: y)
        }

        var path = Path()
        let firstPoint = point(at: 0)
        path.move(to: firstPoint)

        for i in 1..<values.count {
            let prev = point(at: i - 1)
            let curr = point(at: i)
            let midX = (prev.x + curr.x) / 2
            path.addQuadCurve(to: CGPoint(x: midX, y: (prev.y + curr.y) / 2), control: prev)
            path.addQuadCurve(to: curr, control: CGPoint(x: midX, y: (prev.y + curr.y) / 2))
        }

        if closed {
            // Close the shape down to the bottom and back
            let lastPoint = point(at: values.count - 1)
            path.addLine(to: CGPoint(x: lastPoint.x, y: rect.height))
            path.addLine(to: CGPoint(x: firstPoint.x, y: rect.height))
            path.closeSubpath()
        }

        return path
    }
}

// MARK: - Data Point Dots

struct PointDotsView: View {
    let values: [Double]
    let size: CGSize
    let color: Color

    var body: some View {
        Canvas { context, canvasSize in
            guard values.count >= 2 else { return }

            let minVal = values.min() ?? 0
            let maxVal = values.max() ?? 1
            let range = maxVal - minVal
            let safeRange = range < 0.01 ? 1.0 : range

            let verticalPadding = canvasSize.height * 0.1
            let drawHeight = canvasSize.height - verticalPadding * 2
            let stepX = canvasSize.width / CGFloat(values.count - 1)

            for i in 0..<values.count {
                let x = CGFloat(i) * stepX
                let normalized = CGFloat((values[i] - minVal) / safeRange)
                let y = canvasSize.height - verticalPadding - normalized * drawHeight
                let center = CGPoint(x: x, y: y)

                // Outer glow
                let outerCircle = Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8))
                context.fill(outerCircle, with: .color(color.opacity(0.2)))

                // Inner dot
                let innerCircle = Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5))
                context.fill(innerCircle, with: .color(color))
            }
        }
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

#Preview("Graph Medium", as: .systemMedium) {
    ForecastGraphWidget()
} timeline: {
    BalanceWidgetEntry.placeholder
}

#Preview("Graph Lock Screen", as: .accessoryRectangular) {
    ForecastGraphWidget()
} timeline: {
    BalanceWidgetEntry.placeholder
}
