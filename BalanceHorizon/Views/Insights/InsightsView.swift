// InsightsView.swift — Balance Horizon
// Smart financial insights screen with animated cards and monthly snapshot.

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Query private var settingsArray: [AppSettings]

    @State private var insightsEngine = InsightsEngine()
    @State private var insights: [Insight] = []
    @State private var cardsVisible = false

    private var settings: AppSettings? { settingsArray.first }
    private let calendar = Calendar.current

    // MARK: - Monthly Snapshot Data

    private var monthStart: Date {
        let comps = calendar.dateComponents([.year, .month], from: Date.now)
        return calendar.date(from: comps)!
    }

    private var thisMonthTransactions: [Transaction] {
        transactions.filter { $0.date >= monthStart && $0.date <= Date.now }
    }

    private var totalIncome: Double {
        thisMonthTransactions.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        thisMonthTransactions.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
    }

    private var netAmount: Double {
        totalIncome - totalExpenses
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if insights.isEmpty {
                    ContentUnavailableView {
                        Label("No Insights Yet", systemImage: "sparkles")
                    } description: {
                        Text("Keep tracking for a week to see insights about your spending habits and financial health.")
                    }
                } else {
                    scrollContent
                }
            }
            .background(Color.secondaryBackground)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { refreshInsights() }
            .onChange(of: transactions.count) { _, _ in refreshInsights() }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                monthlySnapshotCard
                insightCardsList
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .refreshable {
            refreshInsights()
        }
    }

    // MARK: - Monthly Snapshot Card

    private var monthlySnapshotCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Monthly Snapshot")
                    .font(.headline)
                Spacer()
                Text(Date.now.formatted(.dateTime.month(.wide).year()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                snapshotColumn(label: "Income", amount: totalIncome, color: .green, prefix: "+")
                Spacer()
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 52)
                Spacer()
                snapshotColumn(label: "Expenses", amount: totalExpenses, color: .red, prefix: "-")
                Spacer()
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 52)
                Spacer()
                snapshotColumn(label: "Net", amount: netAmount, color: netAmount >= 0 ? .green : .red, prefix: netAmount >= 0 ? "+" : "")
            }
        }
        .padding(20)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.top, 4)
    }

    private func snapshotColumn(label: String, amount: Double, color: Color, prefix: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(prefix)\(abs(amount).currencyFormatted)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Insight Cards List

    private var insightCardsList: some View {
        VStack(spacing: 12) {
            ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                insightCard(insight)
                    .opacity(cardsVisible ? 1 : 0)
                    .offset(y: cardsVisible ? 0 : 20)
                    .animation(
                        .spring(duration: 0.5, bounce: 0.3)
                        .delay(Double(index) * 0.08),
                        value: cardsVisible
                    )
            }
        }
    }

    // MARK: - Single Insight Card

    private func insightCard(_ insight: Insight) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Colored icon circle
            ZStack {
                Circle()
                    .fill(impactColor(insight.impact).opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: insight.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(impactColor(insight.impact))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(insight.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Helpers

    private func impactColor(_ impact: InsightImpact) -> Color {
        switch impact {
        case .positive: return .green
        case .neutral: return .blue
        case .warning: return .orange
        case .negative: return .red
        }
    }

    private func refreshInsights() {
        let balance = settings?.startingBalance ?? 0
        let startDate = settings?.startingBalanceDate ?? Date.now
        insights = insightsEngine.generateInsights(
            transactions: transactions,
            startingBalance: balance,
            startingDate: startDate
        )
        // Reset and trigger staggered animation
        cardsVisible = false
        withAnimation {
            cardsVisible = true
        }
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [Transaction.self, AppSettings.self], inMemory: true)
}
