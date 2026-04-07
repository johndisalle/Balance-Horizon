// TrendsView.swift — Balance Horizon
// Monthly spending trends screen with category breakdown chart and summary.

import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Query private var settingsArray: [AppSettings]

    @State private var selectedMonth: Date = Calendar.current.startOfDay(for: .now)

    private var settings: AppSettings? { settingsArray.first }
    private let calendar = Calendar.current

    // MARK: - Computed Properties

    private var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var monthStart: Date {
        let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
        return calendar.date(from: comps)!
    }

    private var monthEnd: Date {
        calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
    }

    private var monthTransactions: [Transaction] {
        transactions.filter { tx in
            let txMonth = calendar.dateComponents([.year, .month], from: tx.date)
            let selMonth = calendar.dateComponents([.year, .month], from: selectedMonth)
            return txMonth.year == selMonth.year && txMonth.month == selMonth.month
        }
    }

    private var totalIncome: Double {
        monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var netChange: Double {
        totalIncome - totalExpenses
    }

    private var categoryTotals: [(category: String, amount: Double, percentage: Double)] {
        let expenseTransactions = monthTransactions.filter { $0.type == .expense }
        var totals: [String: Double] = [:]
        for tx in expenseTransactions {
            totals[tx.category, default: 0] += tx.amount
        }
        let total = totalExpenses
        return totals
            .map { (category: $0.key, amount: $0.value, percentage: total > 0 ? $0.value / total : 0) }
            .sorted { $0.amount > $1.amount }
    }

    private let categoryColors: [String: Color] = [
        "Salary": .green,
        "Rent": .red,
        "Groceries": .orange,
        "Utilities": .yellow,
        "Transport": .blue,
        "Dining": .pink,
        "Entertainment": .purple,
        "Health": .mint,
        "Shopping": .indigo,
        "Subscriptions": .cyan,
        "Savings": .teal,
        "Gifts": .brown,
        "Education": Color(.systemBlue),
        "Travel": Color(.systemTeal),
        "General": .gray,
        "Bills": .red
    ]

    private func colorForCategory(_ category: String) -> Color {
        categoryColors[category] ?? .gray
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if monthTransactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Add transactions to see your spending trends for \(monthTitle).")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            monthNavigationHeader
                            monthlySummaryCard
                            categoryChart
                            categoryBreakdownList
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(Color.secondaryBackground)
            .navigationTitle("Trends")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Month Navigation

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }
            Spacer()
            Text(monthTitle)
                .font(.title2.weight(.bold))
                .contentTransition(.numericText())
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Monthly Summary Card

    private var monthlySummaryCard: some View {
        VStack(spacing: 16) {
            Text("Monthly Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                summaryColumn(title: "Income", amount: totalIncome, color: .green, prefix: "+")
                Spacer()
                Divider().frame(height: 48)
                Spacer()
                summaryColumn(title: "Expenses", amount: totalExpenses, color: .red, prefix: "-")
                Spacer()
                Divider().frame(height: 48)
                Spacer()
                summaryColumn(title: "Net", amount: netChange, color: netChange >= 0 ? .green : .red, prefix: netChange >= 0 ? "+" : "")
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private func summaryColumn(title: String, amount: Double, color: Color, prefix: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(prefix)\(abs(amount).currencyFormatted)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category Chart

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)

            if categoryTotals.isEmpty {
                Text("No expenses this month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart(categoryTotals, id: \.category) { item in
                    BarMark(
                        x: .value("Amount", item.amount),
                        y: .value("Category", item.category)
                    )
                    .foregroundStyle(colorForCategory(item.category))
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading, spacing: 4) {
                        Text(item.amount.compactCurrency)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .frame(height: max(CGFloat(categoryTotals.count) * 40, 80))
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Category Breakdown List

    private var categoryBreakdownList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown")
                .font(.headline)

            ForEach(categoryTotals, id: \.category) { item in
                HStack(spacing: 12) {
                    Circle()
                        .fill(colorForCategory(item.category))
                        .frame(width: 12, height: 12)

                    Text(item.category)
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Text(item.amount.currencyFormatted)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()

                    Text("\(Int(item.percentage * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 6)

                        Capsule()
                            .fill(colorForCategory(item.category))
                            .frame(width: geo.size.width * item.percentage, height: 6)
                    }
                }
                .frame(height: 6)

                if item.category != categoryTotals.last?.category {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}
