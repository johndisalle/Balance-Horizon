import SwiftUI

struct AddWatchTransactionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var amount: Double = 25.0
    @State private var isIncome: Bool = false
    @State private var selectedCategory: String = "General"

    private let sharedDefaults = UserDefaults(suiteName: "group.com.ellasid.balancehorizon")

    private let categories = ["Groceries", "Dining", "Transport", "Shopping", "General"]
    private let amountRange: ClosedRange<Double> = 5...500
    private let amountStep: Double = 5.0

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // MARK: - Amount (Digital Crown Scrollable)
                Text(formatCurrency(amount))
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(isIncome ? .green : .red)
                    .focusable()
                    .digitalCrownRotation(
                        $amount,
                        from: amountRange.lowerBound,
                        through: amountRange.upperBound,
                        by: amountStep,
                        sensitivity: .medium,
                        isContinuous: false,
                        isHapticFeedbackEnabled: true
                    )

                Text("Scroll Crown to adjust")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.secondary)

                // MARK: - Income / Expense Toggle
                Picker("Type", selection: $isIncome) {
                    Text("Expense").tag(false)
                    Text("Income").tag(true)
                }
                .pickerStyle(.wheel)

                // MARK: - Quick Category Picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.navigationLink)

                // MARK: - Save Button
                Button {
                    saveTransaction()
                } label: {
                    Label("Save", systemImage: "checkmark.circle.fill")
                        .font(.system(.footnote, design: .rounded).bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Add")
    }

    // MARK: - Save

    private func saveTransaction() {
        let transaction: [String: Any] = [
            "id": UUID().uuidString,
            "amount": isIncome ? amount : -amount,
            "category": selectedCategory,
            "isIncome": isIncome,
            "date": ISO8601DateFormatter().string(from: Date()),
            "source": "watch"
        ]

        // Append to pending transactions array for the main app to process
        var pending = sharedDefaults?.array(forKey: "pendingWatchTransactions") as? [[String: Any]] ?? []
        pending.append(transaction)
        sharedDefaults?.set(pending, forKey: "pendingWatchTransactions")
        sharedDefaults?.synchronize()

        // Haptic feedback
        WKInterfaceDevice.current().play(.success)

        dismiss()
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

#Preview {
    AddWatchTransactionView()
}
