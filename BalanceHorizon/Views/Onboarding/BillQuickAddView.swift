// BillQuickAddView.swift — Balance Horizon
// "Scan your recurring bills" — a fast way to add 10+ recurring transactions
// in under 60 seconds during onboarding or from settings.

import SwiftUI
import SwiftData

// MARK: - BillTemplate

struct BillTemplate: Identifiable {
    let id = UUID()
    let name: String
    let defaultAmount: Double
    let frequency: RecurringFrequency
    let category: String
    let icon: String
    var isSelected: Bool = false
    var customAmount: Double?

    var displayAmount: Double {
        customAmount ?? defaultAmount
    }

    var frequencyLabel: String {
        switch frequency {
        case .daily:     return "/day"
        case .weekly:    return "/wk"
        case .biweekly:  return "/2wk"
        case .monthly:   return "/mo"
        case .quarterly: return "/qtr"
        case .yearly:    return "/yr"
        }
    }

    static let allBills: [BillTemplate] = [
        BillTemplate(name: "Netflix",         defaultAmount: 15.49,  frequency: .monthly, category: "Entertainment",  icon: "play.tv"),
        BillTemplate(name: "Spotify",         defaultAmount: 11.99,  frequency: .monthly, category: "Entertainment",  icon: "music.note"),
        BillTemplate(name: "YouTube Premium", defaultAmount: 13.99,  frequency: .monthly, category: "Entertainment",  icon: "play.rectangle"),
        BillTemplate(name: "Disney+",         defaultAmount: 13.99,  frequency: .monthly, category: "Entertainment",  icon: "sparkles.tv"),
        BillTemplate(name: "Gym Membership",  defaultAmount: 30.00,  frequency: .monthly, category: "Health",         icon: "figure.run"),
        BillTemplate(name: "Phone Bill",      defaultAmount: 85.00,  frequency: .monthly, category: "Utilities",      icon: "iphone"),
        BillTemplate(name: "Internet",        defaultAmount: 65.00,  frequency: .monthly, category: "Utilities",      icon: "wifi"),
        BillTemplate(name: "Car Insurance",   defaultAmount: 150.00, frequency: .monthly, category: "Transport",      icon: "car"),
        BillTemplate(name: "Car Payment",     defaultAmount: 350.00, frequency: .monthly, category: "Transport",      icon: "car.fill"),
        BillTemplate(name: "Student Loans",   defaultAmount: 250.00, frequency: .monthly, category: "Education",      icon: "graduationcap"),
        BillTemplate(name: "Electricity",     defaultAmount: 120.00, frequency: .monthly, category: "Utilities",      icon: "bolt.fill"),
        BillTemplate(name: "Water",           defaultAmount: 45.00,  frequency: .monthly, category: "Utilities",      icon: "drop.fill"),
        BillTemplate(name: "Gas/Fuel",        defaultAmount: 50.00,  frequency: .weekly,  category: "Transport",      icon: "fuelpump"),
        BillTemplate(name: "Coffee habit",    defaultAmount: 5.00,   frequency: .daily,   category: "Dining",         icon: "cup.and.saucer"),
        BillTemplate(name: "Lunch at work",   defaultAmount: 12.00,  frequency: .daily,   category: "Dining",         icon: "takeoutbag.and.cup.and.straw"),
    ]
}

// MARK: - BillQuickAddView

struct BillQuickAddView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var bills: [BillTemplate] = BillTemplate.allBills
    @State private var editingBillID: UUID? = nil
    @State private var editingAmountText: String = ""
    @FocusState private var amountFieldFocused: Bool

    /// Called after saving bills (e.g. to advance onboarding).
    var onComplete: (() -> Void)? = nil

    private var selectedBills: [BillTemplate] {
        bills.filter(\.isSelected)
    }

    private var selectedCount: Int {
        selectedBills.count
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    billsList
                    // Bottom spacer so content is not hidden behind the sticky button
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.interactively)

            stickyBottomButton
        }
        .background(Color.secondaryBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip") {
                    dismiss()
                    onComplete?()
                }
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What do you pay for?")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Tap to add your recurring bills. You can always edit later.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    // MARK: - Bills List

    private var billsList: some View {
        VStack(spacing: 10) {
            ForEach(Array(bills.enumerated()), id: \.element.id) { index, bill in
                billCard(bill: bill, index: index)
            }
        }
    }

    private func billCard(bill: BillTemplate, index: Int) -> some View {
        let isSelected = bill.isSelected
        let isEditing = editingBillID == bill.id

        return Button {
            if isEditing { return }
            toggleBill(at: index)
        } label: {
            HStack(spacing: 14) {
                // Left: Icon in colored circle
                iconCircle(for: bill)

                // Middle: Name + frequency
                VStack(alignment: .leading, spacing: 2) {
                    Text(bill.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(bill.frequency.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Right: Amount (editable) + checkmark
                HStack(spacing: 10) {
                    if isEditing {
                        amountEditor(bill: bill, index: index)
                    } else {
                        amountLabel(bill: bill, index: index)
                    }

                    // Checkmark / toggle
                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
                            .frame(width: 26, height: 26)

                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 26, height: 26)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.blue.opacity(0.35) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func iconCircle(for bill: BillTemplate) -> some View {
        let categoryColor = colorForCategory(bill.category)
        return ZStack {
            Circle()
                .fill(categoryColor.opacity(0.15))
                .frame(width: 42, height: 42)

            Image(systemName: bill.icon)
                .font(.system(size: 18))
                .foregroundStyle(categoryColor)
        }
    }

    private func amountLabel(bill: BillTemplate, index: Int) -> some View {
        Button {
            editingBillID = bill.id
            editingAmountText = String(format: "%.2f", bill.displayAmount)
            amountFieldFocused = true
        } label: {
            Text("$\(bill.displayAmount, specifier: "%.2f")\(bill.frequencyLabel)")
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundStyle(bill.isSelected ? .blue : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func amountEditor(bill: BillTemplate, index: Int) -> some View {
        HStack(spacing: 2) {
            Text("$")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)

            TextField("0.00", text: $editingAmountText)
                .font(.subheadline.weight(.medium).monospacedDigit())
                .keyboardType(.decimalPad)
                .frame(width: 70)
                .focused($amountFieldFocused)
                .onSubmit { commitAmountEdit(index: index) }
                .onChange(of: amountFieldFocused) { _, focused in
                    if !focused { commitAmountEdit(index: index) }
                }

            Text(bill.frequencyLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Sticky Bottom Button

    private var stickyBottomButton: some View {
        VStack(spacing: 0) {
            // Fade-out edge
            LinearGradient(
                colors: [Color.secondaryBackground.opacity(0), Color.secondaryBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            VStack(spacing: 12) {
                Button {
                    saveBills()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.body.weight(.semibold))

                        Text(selectedCount > 0 ? "Add \(selectedCount) Bill\(selectedCount == 1 ? "" : "s")" : "Select Bills to Add")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        selectedCount > 0 ? AnyShapeStyle(Color.blue) : AnyShapeStyle(Color.gray.opacity(0.3)),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .foregroundStyle(.white)
                }
                .disabled(selectedCount == 0)
                .animation(.easeInOut(duration: 0.2), value: selectedCount)

                if selectedCount > 0 {
                    let monthlyEstimate = estimatedMonthlyTotal
                    Text("Estimated: \(monthlyEstimate.currencyFormatted)/month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
            .background(Color.secondaryBackground)
        }
    }

    // MARK: - Actions

    private func toggleBill(at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            bills[index].isSelected.toggle()
        }
        let style: UIImpactFeedbackGenerator.FeedbackStyle = bills[index].isSelected ? .medium : .light
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.impactOccurred()
    }

    private func commitAmountEdit(index: Int) {
        let cleaned = editingAmountText.replacingOccurrences(of: ",", with: ".")
        if let value = Double(cleaned), value > 0 {
            bills[index].customAmount = value
        }
        editingBillID = nil
    }

    private func saveBills() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        for bill in selectedBills {
            // Determine a sensible start date
            let startDate: Date
            switch bill.frequency {
            case .daily:
                startDate = today
            case .weekly, .biweekly:
                // Next Monday
                startDate = cal.nextDate(
                    after: today,
                    matching: DateComponents(weekday: 2),
                    matchingPolicy: .nextTimePreservingSmallerComponents
                ) ?? today
            case .monthly, .quarterly, .yearly:
                // 1st of next month
                var comps = cal.dateComponents([.year, .month], from: today)
                comps.month = (comps.month ?? 1) + 1
                comps.day = 1
                startDate = cal.date(from: comps) ?? today
            }

            let transaction = Transaction(
                date: startDate,
                amount: bill.displayAmount,
                type: .expense,
                desc: bill.name,
                category: bill.category,
                isRecurring: true,
                recurringFrequency: bill.frequency
            )
            context.insert(transaction)
        }

        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)

        dismiss()
        onComplete?()
    }

    // MARK: - Helpers

    private var estimatedMonthlyTotal: Double {
        selectedBills.reduce(0) { total, bill in
            let amount = bill.displayAmount
            switch bill.frequency {
            case .daily:     return total + amount * 30
            case .weekly:    return total + amount * 4.33
            case .biweekly:  return total + amount * 2.17
            case .monthly:   return total + amount
            case .quarterly: return total + amount / 3
            case .yearly:    return total + amount / 12
            }
        }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Entertainment": return .purple
        case "Health":        return .pink
        case "Utilities":     return .orange
        case "Transport":     return .blue
        case "Education":     return .indigo
        case "Dining":        return .green
        default:              return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BillQuickAddView()
    }
    .modelContainer(for: [Transaction.self, AppSettings.self], inMemory: true)
}
