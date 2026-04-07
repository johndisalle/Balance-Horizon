// QuickAddView.swift — Balance Horizon
// Ultra-fast transaction entry designed for widget deep links and shortcuts.
// Goal: complete a transaction in 3 seconds or less.

import SwiftUI
import SwiftData

struct QuickAddView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var amount: String = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategory: String = "General"

    private struct QuickCategory: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
    }

    private let quickCategories: [QuickCategory] = [
        QuickCategory(name: "Groceries", icon: "cart.fill"),
        QuickCategory(name: "Dining", icon: "fork.knife"),
        QuickCategory(name: "Transport", icon: "car.fill"),
        QuickCategory(name: "Shopping", icon: "bag.fill"),
        QuickCategory(name: "Bills", icon: "doc.text.fill"),
        QuickCategory(name: "General", icon: "square.grid.2x2.fill")
    ]

    private let categoryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var parsedAmount: Double? {
        let cleaned = amount.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // MARK: - Amount Display
                amountSection

                // MARK: - Income/Expense Toggle
                typeToggle

                // MARK: - Quick Category Grid
                categoryGrid

                Spacer()

                // MARK: - Save Button
                saveButton
            }
            .padding(20)
            .background(Color.secondaryBackground)
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(spacing: 8) {
            Text(type == .income ? "Income" : "Expense")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(type == .income ? "+" : "-")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(type == .income ? .green : .red)

                Text("$")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Type Toggle

    private var typeToggle: some View {
        Picker("Type", selection: $type) {
            ForEach(TransactionType.allCases) { t in
                Text(t.rawValue).tag(t)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        LazyVGrid(columns: categoryColumns, spacing: 12) {
            ForEach(quickCategories) { cat in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedCategory = cat.name
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: cat.icon)
                            .font(.title3)
                        Text(cat.name)
                            .font(.caption.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedCategory == cat.name
                                  ? Color.blue.opacity(0.15)
                                  : Color.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                selectedCategory == cat.name ? Color.blue : Color.clear,
                                lineWidth: 2
                            )
                    )
                }
                .foregroundStyle(selectedCategory == cat.name ? .blue : .primary)
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Save")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    parsedAmount != nil ? Color.blue : Color.blue.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 16)
                )
        }
        .disabled(parsedAmount == nil)
    }

    // MARK: - Save Action

    private func save() {
        guard let value = parsedAmount else { return }

        let tx = Transaction(
            date: .now,
            amount: value,
            type: type,
            desc: "",
            category: selectedCategory,
            isRecurring: false
        )
        context.insert(tx)

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        dismiss()
    }
}
