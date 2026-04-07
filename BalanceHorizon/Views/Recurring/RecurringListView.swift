// RecurringListView.swift — Balance Horizon
// Manages recurring transaction rules. Shows all repeating entries
// with frequency info and allows editing/deleting.

import SwiftUI
import SwiftData

struct RecurringListView: View {
    @Query(filter: #Predicate<Transaction> { $0.isRecurring },
           sort: \Transaction.date) private var recurringTransactions: [Transaction]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if recurringTransactions.isEmpty {
                    ContentUnavailableView {
                        Label("No Recurring Transactions", systemImage: "repeat")
                    } description: {
                        Text("Set up recurring income or expenses to see your projected balance.")
                    }
                } else {
                    List {
                        ForEach(recurringTransactions, id: \.id) { tx in
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(tx.type == .income ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "repeat")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(tx.type == .income ? .green : .red)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tx.desc.isEmpty ? tx.category : tx.desc)
                                        .font(.body.weight(.medium))
                                    HStack(spacing: 4) {
                                        Text(tx.recurringFrequency?.rawValue ?? "")
                                        Text("·")
                                        Text(tx.category)
                                        if let end = tx.recurringEndDate {
                                            Text("· until \(end.shortFormatted)")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(tx.type == .income ? "+\(tx.amount.currencyFormatted)" : "-\(tx.amount.currencyFormatted)")
                                    .font(.body.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(tx.type == .income ? .green : .red)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.secondaryBackground)
            .navigationTitle("Recurring")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddTransactionView()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(recurringTransactions[index])
        }
    }
}
