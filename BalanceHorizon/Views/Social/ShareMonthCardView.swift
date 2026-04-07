// ShareMonthCardView.swift — Balance Horizon
// "Share My Month" feature: renders a beautiful Instagram-story-sized card
// summarizing a month's finances, and lets users share or save it.

import SwiftUI
import SwiftData

// MARK: - MonthShareCard (The Rendered Card)

struct MonthShareCard: View {
    let monthDate: Date
    let totalIncome: Double
    let totalExpenses: Double
    let netChange: Double
    let transactionCount: Int
    let topCategory: String
    let topCategoryAmount: Double
    let dailyBalances: [Double]

    private var saved: Bool { netChange >= 0 }

    private var heroAmount: Double {
        saved ? netChange : totalExpenses
    }

    private var heroText: String {
        saved ? "I saved" : "I spent"
    }

    private var heroSuffix: String {
        saved ? "this month" : "this month"
    }

    // Card dimensions: 1080x1920 aspect ratio (9:16)
    private let cardWidth: CGFloat = 1080
    private let cardHeight: CGFloat = 1920

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            // Content
            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                // Logo
                logoSection
                    .padding(.bottom, 40)

                // Month/year
                monthLabel
                    .padding(.bottom, 50)

                // Hero stat
                heroSection
                    .padding(.bottom, 60)

                // Sparkline chart
                sparklineChart
                    .frame(height: 360)
                    .padding(.horizontal, 80)
                    .padding(.bottom, 60)

                // Stats row
                statsRow
                    .padding(.horizontal, 60)
                    .padding(.bottom, 50)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 100)
                    .padding(.bottom, 40)

                // Bottom stats
                bottomStats
                    .padding(.bottom, 50)

                Spacer()

                // Watermark
                watermark
                    .padding(.bottom, 60)
            }
            .padding(.horizontal, 40)

            // Decorative floating orbs
            decorativeOrbs
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e"),
                    Color(hex: "0f3460"),
                    Color(hex: "1a1a2e")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle radial glow at top
            RadialGradient(
                colors: [
                    Color(hex: "533483").opacity(0.35),
                    Color.clear
                ],
                center: .init(x: 0.3, y: 0.15),
                startRadius: 50,
                endRadius: 600
            )

            // Subtle teal glow at bottom
            RadialGradient(
                colors: [
                    Color(hex: "0f3460").opacity(0.5),
                    Color.clear
                ],
                center: .init(x: 0.7, y: 0.85),
                startRadius: 50,
                endRadius: 500
            )

            // Noise texture overlay
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.03))
        }
    }

    // MARK: - Decorative Orbs

    private var decorativeOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -300, y: -500)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: 300, y: 200)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: 200, y: -300)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Logo

    private var logoSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .cyan.opacity(0.5), radius: 12, x: 0, y: 0)

            Text("Balance Horizon")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))
                .shadow(color: .cyan.opacity(0.3), radius: 8, x: 0, y: 0)
        }
    }

    // MARK: - Month Label

    private var monthLabel: some View {
        Text(monthDate.monthYearFormatted)
            .font(.system(size: 52, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white)
            .tracking(2)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            Text(heroText)
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.7))

            Text(abs(heroAmount).currencyFormatted)
                .font(.system(size: 112, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(Color.white)
                .shadow(
                    color: saved ? Color.green.opacity(0.4) : Color.red.opacity(0.35),
                    radius: 30,
                    x: 0,
                    y: 0
                )
                .shadow(
                    color: saved ? Color.green.opacity(0.2) : Color.red.opacity(0.15),
                    radius: 60,
                    x: 0,
                    y: 0
                )

            Text(heroSuffix)
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Sparkline Chart

    private var sparklineChart: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let points = normalizedPoints(width: w, height: h)

            ZStack {
                // Gradient fill beneath the line
                if points.count >= 2 {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: h))
                        path.addLine(to: points[0])
                        addSmoothCurve(to: &path, points: points)
                        path.addLine(to: CGPoint(x: points[points.count - 1].x, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Main line
                    Path { path in
                        path.move(to: points[0])
                        addSmoothCurve(to: &path, points: points)
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.cyan.opacity(0.8),
                                Color.white.opacity(0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 0)

                    // Endpoint dot
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .white.opacity(0.6), radius: 8, x: 0, y: 0)
                        .position(points[points.count - 1])
                }
            }
        }
    }

    private func normalizedPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard dailyBalances.count >= 2 else {
            return [CGPoint(x: 0, y: height / 2), CGPoint(x: width, y: height / 2)]
        }
        let minVal = dailyBalances.min() ?? 0
        let maxVal = dailyBalances.max() ?? 1
        let range = maxVal - minVal
        let safeRange = range == 0 ? 1.0 : range
        let padding: CGFloat = 30

        return dailyBalances.enumerated().map { index, value in
            let x = width * CGFloat(index) / CGFloat(dailyBalances.count - 1)
            let normalized = CGFloat((value - minVal) / safeRange)
            let y = (height - padding * 2) * (1 - normalized) + padding
            return CGPoint(x: x, y: y)
        }
    }

    private func addSmoothCurve(to path: inout Path, points: [CGPoint]) {
        guard points.count >= 2 else { return }
        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let midX = (prev.x + curr.x) / 2
            path.addCurve(
                to: curr,
                control1: CGPoint(x: midX, y: prev.y),
                control2: CGPoint(x: midX, y: curr.y)
            )
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statColumn(
                icon: "arrow.down.circle.fill",
                iconColor: Color.green,
                label: "Income",
                amount: totalIncome,
                prefix: "+"
            )

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 80)

            statColumn(
                icon: "arrow.up.circle.fill",
                iconColor: Color.red,
                label: "Expenses",
                amount: totalExpenses,
                prefix: "-"
            )

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 80)

            statColumn(
                icon: netChange >= 0 ? "plusminus.circle.fill" : "exclamationmark.circle.fill",
                iconColor: netChange >= 0 ? Color.green : Color.red,
                label: "Net",
                amount: abs(netChange),
                prefix: netChange >= 0 ? "+" : "-"
            )
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func statColumn(icon: String, iconColor: Color, label: String, amount: Double, prefix: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(iconColor)
                .shadow(color: iconColor.opacity(0.4), radius: 6, x: 0, y: 0)

            Text(label)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.6))

            Text("\(prefix)\(amount.compactCurrency)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom Stats

    private var bottomStats: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.cyan.opacity(0.7))
                Text("\(transactionCount) transactions tracked")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            if !topCategory.isEmpty && topCategoryAmount > 0 {
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.yellow.opacity(0.7))
                    Text("Top category: \(topCategory) (\(topCategoryAmount.compactCurrency))")
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
    }

    // MARK: - Watermark

    private var watermark: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.white.opacity(0.45))

            Text("Made with Balance Horizon")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.45))
        }
    }
}

// MARK: - ShareMonthCardView (The Share Screen)

struct ShareMonthCardView: View {
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Query private var settingsArray: [AppSettings]

    @State private var selectedMonth: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date.now)
        return cal.date(from: comps)!
    }()

    @State private var shadowPhase: CGFloat = 0
    @State private var isSharing = false
    @Environment(\.dismiss) private var dismiss

    private var settings: AppSettings? { settingsArray.first }
    private let calendar = Calendar.current

    // MARK: - Computed Data

    private var monthStart: Date { selectedMonth }

    private var monthEnd: Date {
        guard let end = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return monthStart
        }
        return end
    }

    private var monthTransactions: [Transaction] {
        transactions.filter { $0.date >= monthStart && $0.date < monthEnd }
    }

    private var totalIncome: Double {
        monthTransactions.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        monthTransactions.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
    }

    private var netChange: Double {
        totalIncome - totalExpenses
    }

    private var transactionCount: Int {
        monthTransactions.count
    }

    private var topExpenseCategory: (name: String, amount: Double) {
        let expenses = monthTransactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        let totals = grouped.mapValues { $0.reduce(0.0) { $0 + $1.amount } }
        guard let top = totals.max(by: { $0.value < $1.value }) else {
            return ("", 0)
        }
        return (top.key, top.value)
    }

    private var dailyBalances: [Double] {
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        var balances: [Double] = []
        var runningBalance: Double = 0

        for day in 0..<daysInMonth {
            guard let dayDate = calendar.date(byAdding: .day, value: day, to: monthStart) else {
                balances.append(runningBalance)
                continue
            }
            let dayStart = calendar.startOfDay(for: dayDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            let dayTransactions = monthTransactions.filter {
                $0.date >= dayStart && $0.date < dayEnd
            }
            for t in dayTransactions {
                runningBalance += t.signedAmount
            }
            balances.append(runningBalance)
        }
        return balances
    }

    // MARK: - Available Months

    private var availableMonthRange: (earliest: Date, latest: Date) {
        let now = Date.now
        let comps = calendar.dateComponents([.year, .month], from: now)
        let currentMonth = calendar.date(from: comps)!

        if let earliest = transactions.first?.date {
            let eComps = calendar.dateComponents([.year, .month], from: earliest)
            let earliestMonth = calendar.date(from: eComps)!
            return (earliestMonth, currentMonth)
        }
        return (currentMonth, currentMonth)
    }

    private var canGoBack: Bool {
        selectedMonth > availableMonthRange.earliest
    }

    private var canGoForward: Bool {
        selectedMonth < availableMonthRange.latest
    }

    // MARK: - Card Data Object

    private var cardView: MonthShareCard {
        let top = topExpenseCategory
        return MonthShareCard(
            monthDate: selectedMonth,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netChange: netChange,
            transactionCount: transactionCount,
            topCategory: top.name,
            topCategoryAmount: top.amount,
            dailyBalances: dailyBalances
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Month picker
                    monthPicker
                        .padding(.top, 8)

                    // Card preview
                    cardPreview
                        .padding(.horizontal, 24)

                    Spacer()

                    // Action buttons
                    actionButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
            }
            .navigationTitle("Share My Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Month Picker

    private var monthPicker: some View {
        HStack(spacing: 24) {
            Button {
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                    if let prev = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
                        selectedMonth = prev
                    }
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(canGoBack ? Color.accentColor : Color.secondary.opacity(0.3))
            }
            .disabled(!canGoBack)

            Text(selectedMonth.monthYearFormatted)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(minWidth: 180)
                .contentTransition(.numericText())

            Button {
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                    if let next = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
                        selectedMonth = next
                    }
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(canGoForward ? Color.accentColor : Color.secondary.opacity(0.3))
            }
            .disabled(!canGoForward)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Card Preview

    private var cardPreview: some View {
        // Scale the 1080x1920 card to fit the screen
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let availableHeight = geo.size.height
            let cardAspect: CGFloat = 1080 / 1920
            let fitWidth = min(availableWidth, availableHeight * cardAspect)
            let scale = fitWidth / 1080

            cardView
                .scaleEffect(scale, anchor: .top)
                .frame(width: fitWidth, height: fitWidth / cardAspect)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(
                    color: Color.purple.opacity(0.15 + 0.08 * sin(shadowPhase)),
                    radius: 20 + 5 * sin(shadowPhase),
                    x: 0,
                    y: 8 + 3 * sin(shadowPhase)
                )
                .shadow(
                    color: Color.blue.opacity(0.1 + 0.05 * sin(shadowPhase + 1)),
                    radius: 30,
                    x: 0,
                    y: 12
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true)
                    ) {
                        shadowPhase = .pi * 2
                    }
                }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Share button
            Button {
                shareCard()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Share")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "533483"), Color(hex: "0f3460")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 4)
            }

            // Save to Photos button
            Button {
                saveToPhotos()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Save to Photos")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(.tertiarySystemFill))
                .foregroundStyle(Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    // MARK: - Rendering & Sharing

    @MainActor
    private func renderCardImage() -> UIImage? {
        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 2.0 // High resolution
        renderer.proposedSize = .init(width: 1080, height: 1920)
        return renderer.uiImage
    }

    private func shareCard() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        guard let image = renderCardImage() else { return }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // Find the top view controller to present from
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        // iPad popover support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.maxY - 100,
                width: 0,
                height: 0
            )
        }

        topVC.present(activityVC, animated: true)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func saveToPhotos() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        guard let image = renderCardImage() else { return }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Preview

#Preview {
    ShareMonthCardView()
        .modelContainer(for: [Transaction.self, AppSettings.self], inMemory: true)
}

#Preview("Card Only") {
    MonthShareCard(
        monthDate: Date.now,
        totalIncome: 5200,
        totalExpenses: 3800,
        netChange: 1400,
        transactionCount: 47,
        topCategory: "Dining",
        topCategoryAmount: 820,
        dailyBalances: (0..<30).map { day in
            Double(day) * 50 + Double.random(in: -200...200)
        }
    )
    .scaleEffect(0.35)
    .frame(width: 378, height: 672)
}
