// TransactionListView.swift — Balance Horizon
// Chronological list of all transactions with filtering by month and type.

import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Environment(\.modelContext) private var context

    @State private var filterType: TransactionType? = nil
    @State private var showingAdd = false

    private var filtered: [Transaction] {
        transactions.filter { tx in
            if let filterType { return tx.type == filterType }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                HStack(spacing: 8) {
                    FilterChip(label: "All", isSelected: filterType == nil) {
                        filterType = nil
                    }
                    FilterChip(label: "Income", isSelected: filterType == .income) {
                        filterType = .income
                    }
                    FilterChip(label: "Expenses", isSelected: filterType == .expense) {
                        filterType = .expense
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                if filtered.isEmpty {
                    ContentUnavailableView {
                        Label("No Transactions", systemImage: "tray")
                    } description: {
                        Text("Add your first transaction to get started.")
                    }
                } else {
                    List {
                        ForEach(filtered, id: \.id) { tx in
                            TransactionRow(transaction: tx)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.secondaryBackground)
            .navigationTitle("Transactions")
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
            context.delete(filtered[index])
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(transaction.type == .income ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.type == .income ? "arrow.down.left" : "arrow.up.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(transaction.type == .income ? .green : .red)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.desc.isEmpty ? transaction.category : transaction.desc)
                    .font(.body.weight(.medium))
                HStack(spacing: 4) {
                    Text(transaction.category)
                    if transaction.isRecurring {
                        Image(systemName: "repeat")
                    }
                    Text("·")
                    Text(transaction.date.shortFormatted)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(transaction.type == .income ? "+\(transaction.amount.currencyFormatted)" : "-\(transaction.amount.currencyFormatted)")
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(transaction.type == .income ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? .blue : Color.secondaryBackground, in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}
