// CalendarViewModel.swift — Balance Horizon
// Drives the main calendar screen. Manages current month navigation,
// fetches transactions from SwiftData, runs the projection engine,
// and exposes per-day balance data to the calendar grid.

import Foundation
import SwiftData
import SwiftUI

@Observable
final class CalendarViewModel {
    var currentMonth: Date = Calendar.current.startOfDay(for: .now)
    var dayBalances: [Date: DayBalance] = [:]
    var selectedDay: Date? = nil
    var showingDayDetail = false
    var showingAddTransaction = false

    private let engine = ProjectionEngine()

    var monthTitle: String {
        currentMonth.formatted(.dateTime.month(.wide).year())
    }

    var daysInMonth: [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: currentMonth) else { return [] }
        return range.compactMap { day in
            cal.date(bySetting: .day, value: day, of: currentMonth)
        }
    }

    /// Padding days so the grid starts on the correct weekday
    var leadingEmptyDays: Int {
        let cal = Calendar.current
        guard let firstDay = daysInMonth.first else { return 0 }
        // Weekday: 1=Sun, 2=Mon...7=Sat. Grid starts Sunday.
        return cal.component(.weekday, from: firstDay) - 1
    }

    func goToPreviousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
        }
    }

    func goToNextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
        }
    }

    func goToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.startOfDay(for: .now)
        }
    }

    func selectDay(_ date: Date) {
        selectedDay = date
        showingDayDetail = true
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func refreshProjections(transactions: [Transaction], settings: AppSettings?) {
        guard let settings else { return }
        let cal = Calendar.current

        // Compute from starting balance date to 12 months ahead
        let rangeStart = cal.date(byAdding: .month, value: -1, to: currentMonth)!
        let rangeEnd = cal.date(byAdding: .month, value: 13, to: currentMonth)!

        dayBalances = engine.computeBalances(
            transactions: transactions,
            startingBalance: settings.startingBalance,
            startingDate: settings.startingBalanceDate,
            from: rangeStart,
            to: rangeEnd
        )
    }

    func balanceForDay(_ date: Date) -> Double? {
        let day = Calendar.current.startOfDay(for: date)
        return dayBalances[day]?.balance
    }

    func transactionsForDay(_ date: Date) -> [Transaction] {
        let day = Calendar.current.startOfDay(for: date)
        return dayBalances[day]?.transactions ?? []
    }

    func balanceColor(_ balance: Double) -> Color {
        if balance < 0 { return .red }
        if balance < 100 { return .orange }
        return .green
    }
}
