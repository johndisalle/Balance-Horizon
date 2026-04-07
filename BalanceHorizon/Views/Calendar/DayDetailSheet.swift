// DayDetailSheet.swift — Balance Horizon
// Modal sheet shown when tapping a day. Displays the day's transactions
// and the projected ending balance.

import SwiftUI

struct DayDetailSheet: View {
    let date: Date
    let balance: Double?
    let transactions: [Transaction]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Balance header
                VStack(spacing: 8) {
                    Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let balance {
                        Text(balance.currencyFormatted)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(balance >= 0 ? Color.primary : Color.red)
                    }

                    Text("Projected Balance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)

                Divider()

                // Transaction list
                if transactions.isEmpty {
                    ContentUnavailableView {
                        Label("No Transactions", systemImage: "tray")
                    } description: {
                        Text("No transactions on this day.")
                    }
                } else {
                    List {
                        ForEach(transactions, id: \.id) { tx in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tx.desc.isEmpty ? tx.category : tx.desc)
                                        .font(.body.weight(.medium))
                                    Text(tx.category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if tx.isRecurring {
                                        Label(tx.recurringFrequency?.rawValue ?? "Recurring", systemImage: "repeat")
                                            .font(.caption2)
                                            .foregroundStyle(.blue)
                                    }
                                }
                                Spacer()
                                Text(tx.signedAmount >= 0 ? "+\(tx.amount.currencyFormatted)" : "-\(tx.amount.currencyFormatted)")
                                    .font(.body.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(tx.type == .income ? .green : .red)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
