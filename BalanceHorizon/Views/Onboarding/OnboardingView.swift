// OnboardingView.swift — Balance Horizon
// 4-screen walkthrough: welcome, concept, balance entry, and a live preview
// showing the calendar populated with sample data so users instantly see the value.
// After onboarding, sample recurring transactions are created so the calendar is alive.

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var settingsArray: [AppSettings]
    @Environment(\.modelContext) private var context
    @State private var currentPage = 0
    @State private var startingBalance: String = ""
    @State private var showPreview = false
    @State private var showBillQuickAdd = false

    private var settings: AppSettings {
        if let existing = settingsArray.first { return existing }
        let new = AppSettings()
        context.insert(new)
        return new
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                conceptPage.tag(1)
                balancePage.tag(2)
                billsPage.tag(3)
                previewPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: currentPage)

            // Bottom button
            Button {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                if currentPage == 3 {
                    // Bills page — show the bill quick-add sheet
                    showBillQuickAdd = true
                } else if currentPage < 4 {
                    withAnimation { currentPage += 1 }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(buttonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(buttonEnabled ? .blue : .gray.opacity(0.3), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .disabled(!buttonEnabled)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .sheet(isPresented: $showBillQuickAdd) {
                BillQuickAddView {
                    showBillQuickAdd = false
                    withAnimation { currentPage = 4 }
                }
            }
        }
        .background(Color.secondaryBackground)
    }

    private var buttonTitle: String {
        switch currentPage {
        case 0, 1: return "Next"
        case 2: return "Next"
        case 3: return "Add My Bills"
        case 4: return "Start Using Balance Horizon"
        default: return "Next"
        }
    }

    private var buttonEnabled: Bool {
        if currentPage == 2 { return parsedBalance != nil }
        return true
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 140, height: 140)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse)
            }

            Text("Balance Horizon")
                .font(.largeTitle.weight(.bold))

            Text("Your financial future,\none day at a time.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // MARK: - Page 2: Concept

    private var conceptPage: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.green.opacity(0.1))
                    .frame(width: 140, height: 140)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
            }

            Text("See Tomorrow's\nBalance Today")
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                ConceptRow(icon: "plus.circle.fill", color: .green, text: "Add income & expenses")
                ConceptRow(icon: "repeat.circle.fill", color: .blue, text: "Set up recurring bills & salary")
                ConceptRow(icon: "calendar.circle.fill", color: .orange, text: "See every day's projected balance")
                ConceptRow(icon: "lock.shield.fill", color: .purple, text: "100% private — no bank sync needed")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }

    // MARK: - Page 3: Balance Entry

    private var balancePage: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.orange.opacity(0.1))
                    .frame(width: 140, height: 140)
                Image(systemName: "banknote")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)
            }

            Text("What's Your Balance?")
                .font(.title.weight(.bold))

            Text("Enter your current checking account balance.\nWe'll project it forward for you.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack {
                Text("$")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $startingBalance)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.blue.opacity(0.3), lineWidth: 1))
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }

    // MARK: - Page 4: Bills

    private var billsPage: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.purple.opacity(0.1))
                    .frame(width: 140, height: 140)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.purple)
            }

            Text("Add Your Bills")
                .font(.title.weight(.bold))

            Text("Quickly add your recurring bills and subscriptions.\nThis is what makes your projections accurate.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Show some example pills
            HStack(spacing: 8) {
                BillPill(name: "Netflix", icon: "play.tv")
                BillPill(name: "Rent", icon: "house")
                BillPill(name: "Gym", icon: "figure.run")
                BillPill(name: "+12 more", icon: "plus")
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Page 5: Live Preview

    private var previewPage: some View {
        VStack(spacing: 16) {
            Text("Here's Your Future")
                .font(.title2.weight(.bold))
                .padding(.top, 20)

            Text("Based on common bills, here's what your balance could look like:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Mini calendar preview
            previewCalendar
                .padding(.horizontal, 12)

            // Sample transactions shown
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample transactions added:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                SampleRow(icon: "arrow.down.left", color: .green, text: "Salary", amount: "+$3,000/mo")
                SampleRow(icon: "arrow.up.right", color: .red, text: "Rent", amount: "-$1,200/mo")
                SampleRow(icon: "arrow.up.right", color: .red, text: "Groceries", amount: "-$150/wk")
                SampleRow(icon: "arrow.up.right", color: .red, text: "Utilities", amount: "-$120/mo")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            Text("You can edit or delete these anytime.")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer(minLength: 0)
        }
    }

    private var previewCalendar: some View {
        let balance = parsedBalance ?? 2500
        let sampleDays = generateSampleWeek(startingBalance: balance)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(sampleDays, id: \.date) { day in
                VStack(spacing: 2) {
                    Text(day.date.dayNumber)
                        .font(.caption2.weight(.medium))
                    Text(day.balance.compactCurrency)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(balanceColor(day.balance))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private var parsedBalance: Double? {
        let cleaned = startingBalance.replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }

    private func balanceColor(_ balance: Double) -> Color {
        if balance < 0 { return .red }
        if balance < 100 { return .orange }
        return .green
    }

    private struct SampleDay {
        let date: Date
        let balance: Double
    }

    private func generateSampleWeek(startingBalance: Double) -> [SampleDay] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var balance = startingBalance
        var days: [SampleDay] = []

        for i in 0..<14 {
            let date = cal.date(byAdding: .day, value: i, to: today)!
            // Simulate: salary on 1st, rent on 1st, groceries weekly, small daily expenses
            let dayOfMonth = cal.component(.day, from: date)
            let weekday = cal.component(.weekday, from: date)

            if dayOfMonth == 1 {
                balance += 3000  // salary
                balance -= 1200  // rent
            }
            if weekday == 2 { // Monday = groceries
                balance -= 150
            }
            balance -= Double.random(in: 10...35) // daily spending

            days.append(SampleDay(date: date, balance: balance))
        }
        return days
    }

    private func completeOnboarding() {
        guard let balance = parsedBalance else { return }
        settings.startingBalance = balance
        settings.startingBalanceDate = Calendar.current.startOfDay(for: .now)
        settings.hasCompletedOnboarding = true
        settings.firstLaunchDate = Date.now

        // Add a default salary if user didn't add one via bills
        addDefaultSalaryIfNeeded()

        // Request notification permission and schedule morning balance
        Task {
            let notifManager = NotificationManager()
            await notifManager.requestPermission()
            await notifManager.scheduleMorningBalance(balance: balance)
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func addDefaultSalaryIfNeeded() {
        // Check if user already added income via bill quick-add
        let descriptor = FetchDescriptor<Transaction>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let hasIncome = existing.contains { $0.type == .income }

        if !hasIncome {
            let cal = Calendar.current
            let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: .now))!
            let salary = Transaction(
                date: firstOfMonth,
                amount: 3000,
                type: .income,
                desc: "Monthly Salary",
                category: "Salary",
                isRecurring: true,
                recurringFrequency: .monthly
            )
            context.insert(salary)
        }
    }
}

// MARK: - Supporting Views

private struct ConceptRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(text)
                .font(.body)
        }
    }
}

private struct SampleRow: View {
    let icon: String
    let color: Color
    let text: String
    let amount: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(text)
                .font(.caption)
            Spacer()
            Text(amount)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(color)
        }
    }
}

private struct BillPill: View {
    let name: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(name)
                .font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1), in: Capsule())
        .foregroundStyle(.blue)
    }
}
