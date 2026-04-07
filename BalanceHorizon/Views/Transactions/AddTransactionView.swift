// AddTransactionView.swift — Balance Horizon
// Form for adding or editing a transaction. Supports one-time and recurring entries.
// Haptic feedback on save for a premium feel.

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsArray: [AppSettings]

    var preselectedDate: Date?

    @State private var date: Date = .now
    @State private var amount: String = ""
    @State private var type: TransactionType = .expense
    @State private var description: String = ""
    @State private var category: String = "General"
    @State private var isRecurring: Bool = false
    @State private var frequency: RecurringFrequency = .monthly
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: .now)!

    private var categories: [String] {
        settingsArray.first?.categories ?? AppSettings.defaultCategories
    }

    var body: some View {
        NavigationStack {
            Form {
                // Type picker
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                // Amount
                Section("Amount") {
                    HStack {
                        Text(type == .income ? "+" : "-")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(type == .income ? .green : .red)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                }

                // Details
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Description", text: $description)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                // Recurring
                Section("Recurring") {
                    Toggle("Repeating Transaction", isOn: $isRecurring.animation())
                    if isRecurring {
                        Picker("Frequency", selection: $frequency) {
                            ForEach(RecurringFrequency.allCases) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        Toggle("Has End Date", isOn: $hasEndDate.animation())
                        if hasEndDate {
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        }
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.body.weight(.semibold))
                        .disabled(parsedAmount == nil)
                }
            }
            .onAppear {
                if let preselectedDate {
                    date = preselectedDate
                }
            }
        }
    }

    private var parsedAmount: Double? {
        let cleaned = amount.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value > 0 else { return nil }
        return value
    }

    private func save() {
        guard let value = parsedAmount else { return }

        let tx = Transaction(
            date: date,
            amount: value,
            type: type,
            desc: description,
            category: category,
            isRecurring: isRecurring,
            recurringFrequency: isRecurring ? frequency : nil,
            recurringEndDate: isRecurring && hasEndDate ? endDate : nil
        )
        context.insert(tx)

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        dismiss()
    }
}
