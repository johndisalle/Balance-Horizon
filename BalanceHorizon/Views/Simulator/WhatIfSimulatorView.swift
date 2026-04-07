// WhatIfSimulatorView.swift — Balance Horizon
// Interactive "What If" projection simulator. Users toggle hypothetical
// financial scenarios and watch a live chart update comparing their
// current trajectory vs. the what-if projection over the next 3 months.

import SwiftUI
import SwiftData

// MARK: - Subscription Model

private struct SubscriptionOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let amount: Double

    static let presets: [SubscriptionOption] = [
        .init(name: "Netflix", amount: 15.49),
        .init(name: "Spotify", amount: 11.99),
        .init(name: "YouTube Premium", amount: 13.99),
        .init(name: "Gym", amount: 30.00),
        .init(name: "Disney+", amount: 13.99),
        .init(name: "Custom", amount: 0),
    ]
}

// MARK: - View

struct WhatIfSimulatorView: View {
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Query private var settingsArray: [AppSettings]

    private var settings: AppSettings? { settingsArray.first }
    private let engine = ProjectionEngine()
    private let calendar = Calendar.current

    // MARK: Scenario State

    // 1 — Cancel a subscription
    @State private var cancelSubEnabled = false
    @State private var selectedSubscription: SubscriptionOption = SubscriptionOption.presets[0]
    @State private var customSubAmount: Double = 10.0

    // 2 — Cut dining out
    @State private var cutDiningEnabled = false
    @State private var cutDiningPercent: Double = 25

    // 3 — Get a raise
    @State private var raiseEnabled = false
    @State private var raiseAmount: Double = 500

    // 4 — Add a new bill
    @State private var newBillEnabled = false
    @State private var newBillAmount: Double = 50
    @State private var newBillFrequency: RecurringFrequency = .monthly

    // 5 — Increase savings
    @State private var savingsEnabled = false
    @State private var savingsAmount: Double = 200

    // 6 — Cut grocery spending
    @State private var cutGroceriesEnabled = false
    @State private var cutGroceriesPercent: Double = 20

    // MARK: Dates

    private var today: Date { calendar.startOfDay(for: .now) }
    private var threeMonthsLater: Date {
        calendar.date(byAdding: .month, value: 3, to: today)!
    }

    // MARK: Projection Data

    private var currentBalances: [(Date, Double)] {
        balanceSeries(from: transactions)
    }

    private var whatIfBalances: [(Date, Double)] {
        balanceSeries(from: whatIfTransactions)
    }

    private func balanceSeries(from txns: [Transaction]) -> [(Date, Double)] {
        let startingBalance = settings?.startingBalance ?? 0
        let startingDate = settings?.startingBalanceDate ?? today
        let map = engine.computeBalances(
            transactions: txns,
            startingBalance: startingBalance,
            startingDate: startingDate,
            from: today,
            to: threeMonthsLater
        )
        return map.values
            .sorted { $0.date < $1.date }
            .map { ($0.date, $0.balance) }
    }

    // MARK: What-If Transactions

    private var whatIfTransactions: [Transaction] {
        var result = transactions.map { tx -> Transaction in
            // Copy each transaction so we don't mutate the originals
            let copy = Transaction(
                date: tx.date,
                amount: tx.amount,
                type: tx.type,
                desc: tx.desc,
                category: tx.category,
                isRecurring: tx.isRecurring,
                recurringFrequency: tx.recurringFrequency,
                recurringEndDate: tx.recurringEndDate,
                recurringParentID: tx.recurringParentID,
                accountID: tx.accountID
            )
            return copy
        }

        // 1 — Cancel subscription: reduce matching subscription expenses
        if cancelSubEnabled {
            let subAmount = selectedSubscription.name == "Custom"
                ? customSubAmount
                : selectedSubscription.amount
            let subName = selectedSubscription.name.lowercased()

            for i in result.indices {
                let tx = result[i]
                if tx.type == .expense && tx.isRecurring {
                    let matchByName = subName != "custom"
                        && tx.desc.lowercased().contains(subName)
                    let matchByAmount = abs(tx.amount - subAmount) < 1.0
                    if matchByName || matchByAmount {
                        result[i] = Transaction(
                            date: tx.date,
                            amount: 0,
                            type: tx.type,
                            desc: tx.desc,
                            category: tx.category,
                            isRecurring: tx.isRecurring,
                            recurringFrequency: tx.recurringFrequency,
                            recurringEndDate: tx.recurringEndDate,
                            recurringParentID: tx.recurringParentID,
                            accountID: tx.accountID
                        )
                    }
                }
            }

            // Also inject a synthetic removal if no match was found
            let matched = result.contains { tx in
                tx.type == .expense && tx.isRecurring && tx.amount == 0
            }
            if !matched {
                let removal = Transaction(
                    date: today,
                    amount: subAmount,
                    type: .income,
                    desc: "Cancel \(selectedSubscription.name)",
                    category: "Subscriptions",
                    isRecurring: true,
                    recurringFrequency: .monthly
                )
                result.append(removal)
            }
        }

        // 2 — Cut dining
        if cutDiningEnabled {
            let factor = cutDiningPercent / 100.0
            for i in result.indices {
                let tx = result[i]
                if tx.type == .expense
                    && tx.category.lowercased() == "dining" {
                    let reduced = tx.amount * (1.0 - factor)
                    result[i] = Transaction(
                        date: tx.date,
                        amount: reduced,
                        type: tx.type,
                        desc: tx.desc,
                        category: tx.category,
                        isRecurring: tx.isRecurring,
                        recurringFrequency: tx.recurringFrequency,
                        recurringEndDate: tx.recurringEndDate,
                        recurringParentID: tx.recurringParentID,
                        accountID: tx.accountID
                    )
                }
            }
        }

        // 3 — Get a raise
        if raiseEnabled && raiseAmount > 0 {
            let raise = Transaction(
                date: today,
                amount: raiseAmount,
                type: .income,
                desc: "Raise",
                category: "Salary",
                isRecurring: true,
                recurringFrequency: .monthly
            )
            result.append(raise)
        }

        // 4 — Add a new bill
        if newBillEnabled && newBillAmount > 0 {
            let bill = Transaction(
                date: today,
                amount: newBillAmount,
                type: .expense,
                desc: "New Bill",
                category: "Bills",
                isRecurring: true,
                recurringFrequency: newBillFrequency
            )
            result.append(bill)
        }

        // 5 — Increase savings
        if savingsEnabled && savingsAmount > 0 {
            let savings = Transaction(
                date: today,
                amount: savingsAmount,
                type: .expense,
                desc: "Extra Savings",
                category: "Savings",
                isRecurring: true,
                recurringFrequency: .monthly
            )
            result.append(savings)
        }

        // 6 — Cut groceries
        if cutGroceriesEnabled {
            let factor = cutGroceriesPercent / 100.0
            for i in result.indices {
                let tx = result[i]
                if tx.type == .expense
                    && tx.category.lowercased() == "groceries" {
                    let reduced = tx.amount * (1.0 - factor)
                    result[i] = Transaction(
                        date: tx.date,
                        amount: reduced,
                        type: tx.type,
                        desc: tx.desc,
                        category: tx.category,
                        isRecurring: tx.isRecurring,
                        recurringFrequency: tx.recurringFrequency,
                        recurringEndDate: tx.recurringEndDate,
                        recurringParentID: tx.recurringParentID,
                        accountID: tx.accountID
                    )
                }
            }
        }

        return result
    }

    // MARK: Delta

    private var endDelta: Double {
        let currentEnd = currentBalances.last?.1 ?? 0
        let whatIfEnd = whatIfBalances.last?.1 ?? 0
        return whatIfEnd - currentEnd
    }

    private var anyScenarioActive: Bool {
        cancelSubEnabled || cutDiningEnabled || raiseEnabled
            || newBillEnabled || savingsEnabled || cutGroceriesEnabled
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    chartSection
                    if anyScenarioActive {
                        deltaCard
                    }
                    scenariosSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color.secondaryBackground)
            .navigationTitle("What If?")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Legend
            HStack(spacing: 16) {
                legendPill(label: "Current", color: .blue)
                if anyScenarioActive {
                    legendPill(
                        label: "What If",
                        color: endDelta >= 0 ? .green : .red
                    )
                }
            }
            .padding(.bottom, 4)

            // Chart
            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    if anyScenarioActive {
                        fillBetweenPaths(in: size)
                    }
                    chartLine(data: currentBalances, in: size, color: .blue, dashed: false)
                    if anyScenarioActive {
                        chartLine(
                            data: whatIfBalances,
                            in: size,
                            color: endDelta >= 0 ? .green : .red,
                            dashed: true
                        )
                    }
                }
            }
            .frame(height: 200)
            .padding(.top, 4)

            // Date labels
            HStack {
                Text(today.shortFormatted)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(threeMonthsLater.shortFormatted)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private func legendPill(label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 16, height: 4)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1), in: Capsule())
    }

    // MARK: Chart Drawing Helpers

    private func chartMinMax(data1: [(Date, Double)], data2: [(Date, Double)]) -> (min: Double, max: Double) {
        let all = data1.map(\.1) + data2.map(\.1)
        let lo = all.min() ?? 0
        let hi = all.max() ?? 1
        let pad = max((hi - lo) * 0.1, 1)
        return (lo - pad, hi + pad)
    }

    private func point(
        for entry: (Date, Double),
        index: Int,
        count: Int,
        in size: CGSize,
        minVal: Double,
        maxVal: Double
    ) -> CGPoint {
        let x = count > 1
            ? size.width * CGFloat(index) / CGFloat(count - 1)
            : size.width / 2
        let range = maxVal - minVal
        let y = range > 0
            ? size.height * (1 - CGFloat((entry.1 - minVal) / range))
            : size.height / 2
        return CGPoint(x: x, y: y)
    }

    private func chartLine(
        data: [(Date, Double)],
        in size: CGSize,
        color: Color,
        dashed: Bool
    ) -> some View {
        let bounds = chartMinMax(data1: currentBalances, data2: anyScenarioActive ? whatIfBalances : currentBalances)
        let path = smoothPath(data: data, in: size, minVal: bounds.min, maxVal: bounds.max)

        return path
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: 2.5,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: dashed ? [8, 6] : []
                )
            )
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: data.map(\.1))
    }

    private func smoothPath(
        data: [(Date, Double)],
        in size: CGSize,
        minVal: Double,
        maxVal: Double
    ) -> Path {
        Path { path in
            guard data.count >= 2 else { return }
            let points = data.enumerated().map { idx, entry in
                point(for: entry, index: idx, count: data.count, in: size, minVal: minVal, maxVal: maxVal)
            }
            path.move(to: points[0])
            for i in 1..<points.count {
                let prev = points[i - 1]
                let curr = points[i]
                let midX = (prev.x + curr.x) / 2
                path.addQuadCurve(
                    to: curr,
                    control: CGPoint(x: midX, y: prev.y)
                )
            }
        }
    }

    private func fillBetweenPaths(in size: CGSize) -> some View {
        let bounds = chartMinMax(data1: currentBalances, data2: whatIfBalances)
        let currentPoints = currentBalances.enumerated().map { idx, entry in
            point(for: entry, index: idx, count: currentBalances.count, in: size, minVal: bounds.min, maxVal: bounds.max)
        }
        let whatIfPoints = whatIfBalances.enumerated().map { idx, entry in
            point(for: entry, index: idx, count: whatIfBalances.count, in: size, minVal: bounds.min, maxVal: bounds.max)
        }

        let fillPath = Path { path in
            guard currentPoints.count >= 2, whatIfPoints.count >= 2 else { return }

            // Forward along current line
            path.move(to: currentPoints[0])
            for i in 1..<currentPoints.count {
                let prev = currentPoints[i - 1]
                let curr = currentPoints[i]
                let midX = (prev.x + curr.x) / 2
                path.addQuadCurve(to: curr, control: CGPoint(x: midX, y: prev.y))
            }

            // Backward along what-if line
            let rev = whatIfPoints.reversed()
            if let first = rev.first {
                path.addLine(to: first)
            }
            let revArr = Array(rev)
            for i in 1..<revArr.count {
                let prev = revArr[i - 1]
                let curr = revArr[i]
                let midX = (prev.x + curr.x) / 2
                path.addQuadCurve(to: curr, control: CGPoint(x: midX, y: prev.y))
            }
            path.closeSubpath()
        }

        let fillColor: Color = endDelta >= 0 ? .green : .red
        return fillPath
            .fill(
                LinearGradient(
                    colors: [fillColor.opacity(0.25), fillColor.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: whatIfBalances.map(\.1))
    }

    // MARK: - Delta Card

    private var deltaCard: some View {
        let positive = endDelta >= 0
        return VStack(spacing: 4) {
            Text("In 3 months, you'd have")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text(abs(endDelta).currencyFormatted)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(positive ? .green : .red)
                    .contentTransition(.numericText())
                Text(positive ? "more" : "less")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(positive ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            (positive ? Color.green : Color.red).opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    // MARK: - Scenarios Section

    private var scenariosSection: some View {
        VStack(spacing: 12) {
            Text("Scenarios")
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            cancelSubscriptionCard
            cutDiningCard
            raiseCard
            newBillCard
            savingsCard
            cutGroceriesCard
        }
    }

    // MARK: Scenario Cards

    private var cancelSubscriptionCard: some View {
        scenarioCard(
            icon: "tv.slash",
            title: "Cancel a subscription",
            isOn: $cancelSubEnabled,
            tint: .red
        ) {
            Picker("Subscription", selection: $selectedSubscription) {
                ForEach(SubscriptionOption.presets) { option in
                    Text(option.name == "Custom"
                         ? "Custom"
                         : "\(option.name) — \(option.amount.currencyFormatted)")
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.primary)

            if selectedSubscription.name == "Custom" {
                amountField(label: "Amount", value: $customSubAmount)
            }
        }
    }

    private var cutDiningCard: some View {
        scenarioCard(
            icon: "fork.knife",
            title: "Cut dining out",
            isOn: $cutDiningEnabled,
            tint: .orange
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reduce by \(Int(cutDiningPercent))%")
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                Slider(value: $cutDiningPercent, in: 10...100, step: 5)
                    .tint(.orange)
            }
        }
    }

    private var raiseCard: some View {
        scenarioCard(
            icon: "arrow.up.circle.fill",
            title: "Get a raise",
            isOn: $raiseEnabled,
            tint: .green
        ) {
            amountField(label: "Monthly raise", value: $raiseAmount)
        }
    }

    private var newBillCard: some View {
        scenarioCard(
            icon: "doc.text.fill",
            title: "Add a new bill",
            isOn: $newBillEnabled,
            tint: .red
        ) {
            amountField(label: "Bill amount", value: $newBillAmount)
            Picker("Frequency", selection: $newBillFrequency) {
                ForEach(RecurringFrequency.allCases) { freq in
                    Text(freq.rawValue).tag(freq)
                }
            }
            .pickerStyle(.menu)
            .tint(.primary)
        }
    }

    private var savingsCard: some View {
        scenarioCard(
            icon: "banknote.fill",
            title: "Increase savings",
            isOn: $savingsEnabled,
            tint: .teal
        ) {
            amountField(label: "Monthly savings", value: $savingsAmount)
        }
    }

    private var cutGroceriesCard: some View {
        scenarioCard(
            icon: "cart.fill",
            title: "Cut grocery spending",
            isOn: $cutGroceriesEnabled,
            tint: .orange
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reduce by \(Int(cutGroceriesPercent))%")
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                Slider(value: $cutGroceriesPercent, in: 10...50, step: 5)
                    .tint(.orange)
            }
        }
    }

    // MARK: Reusable Scenario Card

    private func scenarioCard<Content: View>(
        icon: String,
        title: String,
        isOn: Binding<Bool>,
        tint: Color,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Toggle("", isOn: Binding(
                    get: { isOn.wrappedValue },
                    set: { newValue in
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            isOn.wrappedValue = newValue
                        }
                    }
                ))
                .labelsHidden()
                .tint(tint)
            }

            if isOn.wrappedValue {
                VStack(alignment: .leading, spacing: 10) {
                    content()
                }
                .padding(.leading, 44)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Amount Field Helper

    private func amountField(label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 2) {
                Text("$")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField(
                    "0",
                    value: value,
                    format: .number.precision(.fractionLength(0...2))
                )
                .font(.system(.body, design: .rounded, weight: .semibold))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Preview

#Preview {
    WhatIfSimulatorView()
        .modelContainer(for: [Transaction.self, AppSettings.self], inMemory: true)
}
