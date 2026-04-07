// DayCell.swift — Balance Horizon
// Individual day cell showing date, projected balance, and smart category icons.
// Features spring animations, press feedback, and long-press for radial quick-add.

import SwiftUI

struct DayCell: View {
    let date: Date
    let balance: Double?
    let balanceColor: Color
    let transactions: [Transaction]

    @State private var isPressed = false
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 1) {
            Text(date.dayNumber)
                .font(.caption.weight(date.isToday ? .bold : .medium))
                .foregroundStyle(date.isToday ? .white : .primary)

            if let balance {
                Text(balance.compactCurrency)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(date.isToday ? .white.opacity(0.9) : balanceColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText(value: balance))
            }

            if !transactions.isEmpty {
                CategoryIconsView(transactions: transactions)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background {
            if date.isToday {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.blue)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondaryBackground)
            }
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .opacity(hasAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double.random(in: 0...0.15))) {
                hasAppeared = true
            }
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(date.shortFormatted), balance: \(balance?.currencyFormatted ?? "unknown")")
        .accessibilityAddTraits(date.isToday ? .isSelected : [])
    }
}
