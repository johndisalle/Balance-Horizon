// CalendarView.swift — Balance Horizon
// Main screen: interactive monthly calendar with color-coded projected balances.
// Includes month navigation, balance chart, and floating add button.

import SwiftUI
import SwiftData
import Charts

struct CalendarView: View {
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Query private var settingsArray: [AppSettings]
    @Environment(\.modelContext) private var context
    @State private var vm = CalendarViewModel()

    private var settings: AppSettings? { settingsArray.first }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 16) {
                        monthNavigationHeader
                        balanceChart
                        calendarGrid
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }
                .background(Color.secondaryBackground)

                addButton
            }
            .navigationTitle("Balance Horizon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") { vm.goToToday() }
                        .font(.subheadline.weight(.medium))
                }
            }
            .sheet(isPresented: $vm.showingDayDetail) {
                DayDetailSheet(
                    date: vm.selectedDay ?? .now,
                    balance: vm.balanceForDay(vm.selectedDay ?? .now),
                    transactions: vm.transactionsForDay(vm.selectedDay ?? .now)
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $vm.showingAddTransaction) {
                AddTransactionView(preselectedDate: vm.selectedDay)
            }
            .onChange(of: transactions.count) { refreshProjections() }
            .onChange(of: vm.currentMonth) { refreshProjections() }
            .onChange(of: settings?.startingBalance) { refreshProjections() }
            .onAppear { refreshProjections() }
        }
    }

    private func refreshProjections() {
        vm.refreshProjections(transactions: transactions, settings: settings)
    }

    // MARK: - Month Navigation

    private var monthNavigationHeader: some View {
        HStack {
            Button { vm.goToPreviousMonth() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }
            Spacer()
            Text(vm.monthTitle)
                .font(.title2.weight(.bold))
                .contentTransition(.numericText())
            Spacer()
            Button { vm.goToNextMonth() } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
            }
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Month: \(vm.monthTitle)")
        .accessibilityHint("Swipe to change months")
    }

    // MARK: - Balance Chart

    private var balanceChart: some View {
        let days = vm.daysInMonth
        let chartData = days.compactMap { day -> (Date, Double)? in
            guard let bal = vm.balanceForDay(day) else { return nil }
            return (day, bal)
        }

        return Group {
            if !chartData.isEmpty {
                Chart(chartData, id: \.0) { item in
                    AreaMark(
                        x: .value("Day", item.0, unit: .day),
                        y: .value("Balance", item.1)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Day", item.0, unit: .day),
                        y: .value("Balance", item.1)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(v.compactCurrency)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
                .frame(height: 120)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 2) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 2) {
                // Leading empty cells
                ForEach(0..<vm.leadingEmptyDays, id: \.self) { _ in
                    Color.clear.frame(height: 64)
                }

                // Actual days
                ForEach(vm.daysInMonth, id: \.self) { date in
                    DayCell(
                        date: date,
                        balance: vm.balanceForDay(date),
                        balanceColor: vm.balanceColor(vm.balanceForDay(date) ?? 0),
                        hasTransactions: !vm.transactionsForDay(date).isEmpty
                    )
                    .onTapGesture { vm.selectDay(date) }
                }
            }
        }
        .padding(8)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            vm.showingAddTransaction = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(.blue, in: Circle())
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Add transaction")
    }
}
