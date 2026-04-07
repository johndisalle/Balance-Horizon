// CalendarView.swift — Balance Horizon
// Main screen: interactive monthly calendar with color-coded projected balances.
// Enhanced with swipe gestures, spring animations, and haptic micro-interactions.

import SwiftUI
import SwiftData
import Charts

struct CalendarView: View {
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Query private var settingsArray: [AppSettings]
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var vm = CalendarViewModel()
    @State private var showQuickAdd = false
    @State private var showPaywall = false
    @State private var showShareCard = false
    @State private var showRadialMenu = false
    @State private var radialMenuDate: Date = .now
    @State private var dragOffset: CGFloat = 0
    @State private var dismissedWidgetPromo = false
    @State private var showGoals = false
    @State private var currentMilestone: Milestone? = nil
    @State private var milestoneTracker = MilestoneTracker()
    @State private var clipboardDetector = ClipboardDetector()
    @State private var voiceManager = VoiceInputManager()
    @State private var showVoiceInput = false
    @State private var recurringSuggestionEngine = RecurringSuggestionEngine()

    private var settings: AppSettings? { settingsArray.first }

    private var columnCount: Int { sizeClass == .regular ? 7 : 7 }
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: sizeClass == .regular ? 4 : 2), count: columnCount)
    }
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                mainContent
                    .navigationTitle("Balance Horizon")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { toolbarItems }
                    .modifier(CalendarSheetsModifier(
                        vm: $vm,
                        showQuickAdd: $showQuickAdd,
                        showPaywall: $showPaywall,
                        showShareCard: $showShareCard,
                        showGoals: $showGoals
                    ))
                    .overlay { radialMenuOverlay }
                    .celebrationOverlay(milestone: currentMilestone) {
                        currentMilestone = nil
                    }

                // Clipboard suggestion banner
                clipboardBanner

                // Recurring suggestion banner
                recurringSuggestionBanner
            }
            .onChange(of: transactions.count) {
                refreshProjections()
                checkMilestones()
                checkRecurringSuggestions()
            }
            .onChange(of: vm.currentMonth) { refreshProjections() }
            .onChange(of: settings?.startingBalance) { refreshProjections() }
            .onAppear {
                refreshProjections()
                checkMilestones()
                clipboardDetector.checkClipboard()
                checkRecurringSuggestions()
            }
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    monthNavigationHeader
                    BudgetGoalRingsBar()
                    widgetPromoBanner
                    balanceChart
                    calendarGrid
                        .offset(x: dragOffset)
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
            }
            .background(Color.secondaryBackground)
            .gesture(swipeGesture)

            addButtonStack
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showShareCard = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Today") {
                vm.goToToday()
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
            }
            .font(.subheadline.weight(.medium))
        }
    }

    @ViewBuilder
    private var radialMenuOverlay: some View {
        if showRadialMenu {
            RadialQuickAddMenu(
                isPresented: $showRadialMenu,
                selectedDate: radialMenuDate
            ) { category, amount in
                let tx = Transaction(
                    date: radialMenuDate,
                    amount: amount,
                    type: .expense,
                    category: category
                )
                context.insert(tx)
            }
        }
    }

    private func refreshProjections() {
        vm.refreshProjections(transactions: transactions, settings: settings)
    }

    // MARK: - Clipboard Banner

    @ViewBuilder
    private var clipboardBanner: some View {
        if clipboardDetector.showingSuggestion {
            ClipboardSuggestionBanner(
                detector: clipboardDetector,
                onAdd: { detectedAmount in
                    let tx = Transaction(
                        date: .now,
                        amount: detectedAmount,
                        type: .expense,
                        category: "General"
                    )
                    context.insert(tx)
                }
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(10)
        }
    }

    // MARK: - Recurring Suggestion Banner

    @ViewBuilder
    private var recurringSuggestionBanner: some View {
        if !recurringSuggestions.isEmpty {
            RecurringSuggestionBanner(
                suggestions: recurringSuggestions,
                onAccept: { suggestion in
                    let tx = Transaction(
                        date: .now,
                        amount: suggestion.amount,
                        type: .expense,
                        desc: suggestion.description,
                        category: suggestion.category,
                        isRecurring: true,
                        recurringFrequency: suggestion.suggestedFrequency
                    )
                    context.insert(tx)
                },
                onDismiss: { _ in }
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .padding(.top, 50)
            .zIndex(9)
        }
    }

    @State private var recurringSuggestions: [RecurringSuggestionEngine.RecurringSuggestion] = []

    private func checkRecurringSuggestions() {
        let suggestions = recurringSuggestionEngine.detectPatterns(transactions: transactions)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            recurringSuggestions = suggestions
        }
    }

    private func checkMilestones() {
        guard let settings else { return }
        let daysSinceStart: Int
        if let first = settings.firstLaunchDate {
            daysSinceStart = Calendar.current.dateComponents([.day], from: first, to: .now).day ?? 0
        } else {
            daysSinceStart = 0
        }

        let todayBalance = vm.balanceForDay(Calendar.current.startOfDay(for: .now)) ?? settings.startingBalance

        // Compute savings rate
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: .now))!
        let monthTransactions = transactions.filter { $0.date >= monthStart }
        let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expenses = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let savingsRate = income > 0 ? (income - expenses) / income : 0

        if let milestone = milestoneTracker.checkMilestones(
            transactionCount: transactions.count,
            daysSinceStart: daysSinceStart,
            currentBalance: todayBalance,
            startingBalance: settings.startingBalance,
            savingsRate: savingsRate
        ) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentMilestone = milestone
                milestoneTracker.markShown(milestone)
            }
        }
    }

    // MARK: - Widget Promo Banner (Paywall Trigger)

    @ViewBuilder
    private var widgetPromoBanner: some View {
        if settings?.isPremium != true && !dismissedWidgetPromo {
            Button {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                showPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.3.group.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("See your balance on your Home Screen")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Unlock widgets with Pro")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("PRO")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue, in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(12)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.blue.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .transition(.move(edge: .top).combined(with: .opacity))
            .swipeActions {
                Button("Dismiss") { withAnimation { dismissedWidgetPromo = true } }
            }
        }
    }

    // MARK: - Swipe Gesture for Month Navigation

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50, coordinateSpace: .local)
            .onChanged { value in
                dragOffset = value.translation.width * 0.3
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    dragOffset = 0
                }
                if value.translation.width < -50 {
                    vm.goToNextMonth()
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                } else if value.translation.width > 50 {
                    vm.goToPreviousMonth()
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                }
            }
    }

    // MARK: - Month Navigation

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                vm.goToPreviousMonth()
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .contentTransition(.symbolEffect(.replace))
            }
            Spacer()
            Text(vm.monthTitle)
                .font(.title2.weight(.bold))
                .contentTransition(.numericText())
            Spacer()
            Button {
                vm.goToNextMonth()
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Month: \(vm.monthTitle)")
        .accessibilityHint("Swipe left or right to change months")
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
                    .interpolationMethod(.catmullRom)
                    LineMark(
                        x: .value("Day", item.0, unit: .day),
                        y: .value("Balance", item.1)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
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
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
                .frame(height: sizeClass == .regular ? 160 : 120)
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
                    Color.clear.frame(height: sizeClass == .regular ? 80 : 64)
                }

                // Actual days
                ForEach(vm.daysInMonth, id: \.self) { date in
                    DayCell(
                        date: date,
                        balance: vm.balanceForDay(date),
                        balanceColor: vm.balanceColor(vm.balanceForDay(date) ?? 0),
                        transactions: vm.transactionsForDay(date)
                    )
                    .onTapGesture { vm.selectDay(date) }
                    .onLongPressGesture {
                        let gen = UIImpactFeedbackGenerator(style: .heavy)
                        gen.impactOccurred()
                        radialMenuDate = date
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showRadialMenu = true
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: vm.currentMonth)
        }
        .padding(8)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Add Buttons

    private var addButtonStack: some View {
        VStack(spacing: 10) {
            // Voice input (microphone)
            VoiceInputButton(manager: voiceManager) { amount, category in
                let tx = Transaction(
                    date: .now,
                    amount: amount,
                    type: .expense,
                    category: category
                )
                context.insert(tx)
            }

            // Quick add (lightning bolt)
            Button {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                showQuickAdd = true
            } label: {
                Image(systemName: "bolt.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.orange, in: Circle())
                    .shadow(color: .orange.opacity(0.3), radius: 6, y: 3)
            }
            .accessibilityLabel("Quick add transaction")

            // Full add
            Button {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                vm.showingAddTransaction = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.blue, in: Circle())
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
            }
            .accessibilityLabel("Add transaction")
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Sheets Modifier (extracted to reduce body complexity)

private struct CalendarSheetsModifier: ViewModifier {
    @Binding var vm: CalendarViewModel
    @Binding var showQuickAdd: Bool
    @Binding var showPaywall: Bool
    @Binding var showShareCard: Bool
    @Binding var showGoals: Bool

    func body(content: Content) -> some View {
        content
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
            .sheet(isPresented: $showQuickAdd) {
                QuickAddView()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showShareCard) {
                ShareMonthCardView()
            }
            .sheet(isPresented: $showGoals) {
                BudgetGoalsView()
            }
    }
}
