// InsightsEngine.swift — Balance Horizon
// Pure math insights engine that analyzes transaction history and produces
// actionable financial insights for the user.

import Foundation
import Observation

// MARK: - Models

enum InsightCategory: String, Codable {
    case spending
    case saving
    case forecast
    case pattern
}

enum InsightImpact: Int, Codable, Comparable {
    case negative = 0
    case warning = 1
    case neutral = 2
    case positive = 3

    static func < (lhs: InsightImpact, rhs: InsightImpact) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct Insight: Identifiable {
    let id: UUID
    let icon: String
    let title: String
    let detail: String
    let category: InsightCategory
    let impact: InsightImpact

    init(icon: String, title: String, detail: String, category: InsightCategory, impact: InsightImpact) {
        self.id = UUID()
        self.icon = icon
        self.title = title
        self.detail = detail
        self.category = category
        self.impact = impact
    }
}

// MARK: - Engine

@Observable
class InsightsEngine {
    private let calendar = Calendar.current

    func generateInsights(
        transactions: [Transaction],
        startingBalance: Double,
        startingDate: Date
    ) -> [Insight] {
        let now = Date.now
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        // Require at least 7 days of transaction history
        let earliestTransaction = transactions.map(\.date).min()
        guard let earliest = earliestTransaction,
              earliest <= sevenDaysAgo else {
            return []
        }

        var insights: [Insight] = []

        if let insight = weekendVsWeekdayInsight(transactions: transactions) {
            insights.append(insight)
        }
        if let insight = projectedBalanceInsight(transactions: transactions, startingBalance: startingBalance, startingDate: startingDate) {
            insights.append(insight)
        }
        insights.append(contentsOf: categoryComparisonInsights(transactions: transactions))
        if let insight = daysUntilNextIncomeInsight(transactions: transactions) {
            insights.append(insight)
        }
        if let insight = biggestExpenseInsight(transactions: transactions) {
            insights.append(insight)
        }
        if let insight = savingsRateInsight(transactions: transactions) {
            insights.append(insight)
        }
        if let insight = spendingStreakInsight(transactions: transactions) {
            insights.append(insight)
        }
        if let insight = balanceTrendInsight(transactions: transactions, startingBalance: startingBalance, startingDate: startingDate) {
            insights.append(insight)
        }

        // Sort: warnings/negative first, then neutral, then positive
        insights.sort { $0.impact < $1.impact }

        return insights
    }

    // MARK: - 1. Weekend vs Weekday Spending

    private func weekendVsWeekdayInsight(transactions: [Transaction]) -> Insight? {
        let now = Date.now
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!

        let recentExpenses = transactions.filter {
            $0.type == .expense && $0.date >= thirtyDaysAgo && $0.date <= now
        }
        guard !recentExpenses.isEmpty else { return nil }

        var weekendTotal: Double = 0
        var weekdayTotal: Double = 0
        var weekendDays: Set<DateComponents> = []
        var weekdayDays: Set<DateComponents> = []

        for tx in recentExpenses {
            let weekday = calendar.component(.weekday, from: tx.date)
            let dayComp = calendar.dateComponents([.year, .month, .day], from: tx.date)
            let isWeekend = weekday == 1 || weekday == 7
            if isWeekend {
                weekendTotal += tx.amount
                weekendDays.insert(dayComp)
            } else {
                weekdayTotal += tx.amount
                weekdayDays.insert(dayComp)
            }
        }

        // Count actual weekend/weekday days in the 30-day range for averaging
        var weekendDayCount = 0
        var weekdayDayCount = 0
        var scanDate = thirtyDaysAgo
        while scanDate <= now {
            let wd = calendar.component(.weekday, from: scanDate)
            if wd == 1 || wd == 7 {
                weekendDayCount += 1
            } else {
                weekdayDayCount += 1
            }
            scanDate = calendar.date(byAdding: .day, value: 1, to: scanDate)!
        }

        guard weekendDayCount > 0, weekdayDayCount > 0 else { return nil }

        let avgWeekend = weekendTotal / Double(weekendDayCount)
        let avgWeekday = weekdayTotal / Double(weekdayDayCount)

        guard avgWeekday > 0 else { return nil }

        let percentDiff = ((avgWeekend - avgWeekday) / avgWeekday) * 100
        let absDiff = Int(abs(percentDiff).rounded())

        if absDiff < 1 { return nil }

        if percentDiff > 0 {
            return Insight(
                icon: "calendar.badge.exclamationmark",
                title: "Weekend Spender",
                detail: "You spend \(absDiff)% more on weekends (\(avgWeekend.currencyFormatted)/day) vs weekdays (\(avgWeekday.currencyFormatted)/day).",
                category: .pattern,
                impact: absDiff > 30 ? .warning : .neutral
            )
        } else {
            return Insight(
                icon: "calendar.badge.exclamationmark",
                title: "Weekday Spender",
                detail: "You spend \(absDiff)% less on weekends than weekdays. Nice restraint!",
                category: .pattern,
                impact: .positive
            )
        }
    }

    // MARK: - 2. Projected Balance at Month End

    private func projectedBalanceInsight(
        transactions: [Transaction],
        startingBalance: Double,
        startingDate: Date
    ) -> Insight? {
        let now = Date.now
        let monthStart = startOfMonth(for: now)
        let monthEnd = endOfMonth(for: now)

        // Calculate current balance
        let allPastTransactions = transactions.filter { $0.date <= now }
        let currentBalance = startingBalance + allPastTransactions.reduce(0.0) { $0 + $1.signedAmount }

        // Calculate daily burn rate from this month's data
        let thisMonthTx = transactions.filter { $0.date >= monthStart && $0.date <= now }
        let daysElapsed = max(1, calendar.dateComponents([.day], from: monthStart, to: now).day ?? 1)
        let monthNet = thisMonthTx.reduce(0.0) { $0 + $1.signedAmount }
        let dailyRate = monthNet / Double(daysElapsed)

        let daysRemaining = max(0, (calendar.dateComponents([.day], from: now, to: monthEnd).day ?? 0))
        guard daysRemaining > 0 else { return nil }

        let projectedBalance = currentBalance + (dailyRate * Double(daysRemaining))
        let endDateStr = monthEnd.formatted(.dateTime.month(.abbreviated).day())

        let isUptrend = dailyRate >= 0
        let icon = isUptrend ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis"
        let impact: InsightImpact = projectedBalance < 0 ? .negative : (isUptrend ? .positive : .warning)

        return Insight(
            icon: icon,
            title: "Month-End Forecast",
            detail: "At this rate, you'll have \(projectedBalance.currencyFormatted) by \(endDateStr).",
            category: .forecast,
            impact: impact
        )
    }

    // MARK: - 3. Category Comparison vs Last Month

    private func categoryComparisonInsights(transactions: [Transaction]) -> [Insight] {
        let now = Date.now
        let thisMonthStart = startOfMonth(for: now)
        let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now)!
        let lastMonthStart = startOfMonth(for: lastMonthDate)
        let lastMonthEnd = endOfMonth(for: lastMonthDate)

        let thisMonthExpenses = transactions.filter {
            $0.type == .expense && $0.date >= thisMonthStart && $0.date <= now
        }
        let lastMonthExpenses = transactions.filter {
            $0.type == .expense && $0.date >= lastMonthStart && $0.date <= lastMonthEnd
        }

        guard !lastMonthExpenses.isEmpty else { return [] }

        // Build category totals for both months
        var thisMonthTotals: [String: Double] = [:]
        for tx in thisMonthExpenses {
            thisMonthTotals[tx.category, default: 0] += tx.amount
        }

        var lastMonthTotals: [String: Double] = [:]
        for tx in lastMonthExpenses {
            lastMonthTotals[tx.category, default: 0] += tx.amount
        }

        // Scale this month's spending to full-month estimate for fairer comparison
        let daysElapsed = max(1, calendar.dateComponents([.day], from: thisMonthStart, to: now).day ?? 1)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let scaleFactor = Double(daysInMonth) / Double(daysElapsed)

        // Top 3 expense categories this month
        let topCategories = thisMonthTotals
            .sorted { $0.value > $1.value }
            .prefix(3)

        var insights: [Insight] = []

        for (category, thisAmount) in topCategories {
            guard let lastAmount = lastMonthTotals[category], lastAmount > 0 else { continue }
            let projected = thisAmount * scaleFactor
            let percentChange = ((projected - lastAmount) / lastAmount) * 100
            let absChange = Int(abs(percentChange).rounded())

            guard absChange >= 5 else { continue }

            if percentChange > 0 {
                insights.append(Insight(
                    icon: "arrow.up.right",
                    title: "\(category) Trending Up",
                    detail: "\(category) spending is up \(absChange)% vs last month.",
                    category: .spending,
                    impact: absChange > 25 ? .warning : .neutral
                ))
            } else {
                insights.append(Insight(
                    icon: "arrow.down.right",
                    title: "\(category) Trending Down",
                    detail: "\(category) spending is down \(absChange)% vs last month.",
                    category: .spending,
                    impact: .positive
                ))
            }
        }

        return insights
    }

    // MARK: - 4. Days Until Next Income

    private func daysUntilNextIncomeInsight(transactions: [Transaction]) -> Insight? {
        let now = Date.now
        let today = calendar.startOfDay(for: now)

        let futureIncome = transactions
            .filter { $0.type == .income && calendar.startOfDay(for: $0.date) > today }
            .sorted { $0.date < $1.date }

        guard let next = futureIncome.first else { return nil }

        let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: next.date)).day ?? 0
        guard days > 0 else { return nil }

        let daysStr = days == 1 ? "1 day" : "\(days) days"

        return Insight(
            icon: "clock.arrow.circlepath",
            title: "Next Income",
            detail: "You have \(daysStr) until your next income (\(next.amount.currencyFormatted)).",
            category: .forecast,
            impact: days > 14 ? .warning : .neutral
        )
    }

    // MARK: - 5. Biggest Expense This Month

    private func biggestExpenseInsight(transactions: [Transaction]) -> Insight? {
        let now = Date.now
        let monthStart = startOfMonth(for: now)

        let thisMonthExpenses = transactions.filter {
            $0.type == .expense && $0.date >= monthStart && $0.date <= now
        }
        guard let biggest = thisMonthExpenses.max(by: { $0.amount < $1.amount }) else { return nil }

        let description = biggest.desc.isEmpty ? biggest.category : biggest.desc

        return Insight(
            icon: "exclamationmark.triangle",
            title: "Biggest Expense",
            detail: "Your biggest expense this month: \(biggest.amount.currencyFormatted) for \(description).",
            category: .spending,
            impact: .neutral
        )
    }

    // MARK: - 6. Savings Rate

    private func savingsRateInsight(transactions: [Transaction]) -> Insight? {
        let now = Date.now
        let monthStart = startOfMonth(for: now)

        let thisMonth = transactions.filter { $0.date >= monthStart && $0.date <= now }
        let income = thisMonth.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
        let expenses = thisMonth.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }

        guard income > 0 else { return nil }

        let saved = income - expenses
        let savingsRate = (saved / income) * 100

        if savingsRate > 0 {
            let rateStr = Int(savingsRate.rounded())
            let impact: InsightImpact = rateStr >= 20 ? .positive : .neutral
            return Insight(
                icon: "leaf.fill",
                title: "Savings Rate",
                detail: "You're saving \(rateStr)% of your income this month.",
                category: .saving,
                impact: impact
            )
        } else {
            return Insight(
                icon: "flame.fill",
                title: "Overspending Alert",
                detail: "You're spending more than you earn this month.",
                category: .saving,
                impact: .negative
            )
        }
    }

    // MARK: - 7. Spending Streak

    private func spendingStreakInsight(transactions: [Transaction]) -> Insight? {
        let now = Date.now
        var streak = 0
        var checkDate = calendar.startOfDay(for: now)

        while true {
            let dayStart = checkDate
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let hasExpense = transactions.contains {
                $0.type == .expense && $0.date >= dayStart && $0.date < dayEnd
            }
            if hasExpense {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        guard streak >= 3 else { return nil }

        let impact: InsightImpact = streak >= 14 ? .warning : (streak >= 7 ? .neutral : .positive)

        return Insight(
            icon: "flame",
            title: "Spending Streak",
            detail: "You've spent money \(streak) days in a row.",
            category: .pattern,
            impact: impact
        )
    }

    // MARK: - 8. Balance Trend (Past 7 Days)

    private func balanceTrendInsight(
        transactions: [Transaction],
        startingBalance: Double,
        startingDate: Date
    ) -> Insight? {
        let now = Date.now
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        let recentTx = transactions.filter { $0.date > sevenDaysAgo && $0.date <= now }
        guard !recentTx.isEmpty else { return nil }

        let netChange = recentTx.reduce(0.0) { $0 + $1.signedAmount }
        let absChange = abs(netChange)

        guard absChange >= 1 else { return nil }

        if netChange >= 0 {
            return Insight(
                icon: "arrow.up.forward",
                title: "Balance Rising",
                detail: "Your balance has increased by \(absChange.currencyFormatted) over the past 7 days.",
                category: .pattern,
                impact: .positive
            )
        } else {
            return Insight(
                icon: "arrow.down.forward",
                title: "Balance Dropping",
                detail: "Your balance has decreased by \(absChange.currencyFormatted) over the past 7 days.",
                category: .pattern,
                impact: netChange < -500 ? .warning : .neutral
            )
        }
    }

    // MARK: - Date Helpers

    private func startOfMonth(for date: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps)!
    }

    private func endOfMonth(for date: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        let monthStart = calendar.date(from: comps)!
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
    }
}
