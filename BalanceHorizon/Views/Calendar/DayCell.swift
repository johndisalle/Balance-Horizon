// DayCell.swift — Balance Horizon
// Individual day cell in the calendar grid showing date number and projected balance.
// Color-coded: green (safe), orange (low), red (negative).

import SwiftUI

struct DayCell: View {
    let date: Date
    let balance: Double?
    let balanceColor: Color
    let hasTransactions: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(date.dayNumber)
                .font(.caption.weight(date.isToday ? .bold : .medium))
                .foregroundStyle(date.isToday ? .white : .primary)

            if let balance {
                Text(balance.compactCurrency)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(balanceColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if hasTransactions {
                Circle()
                    .fill(.blue)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background {
            if date.isToday {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.blue)
                    .opacity(0.8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondaryBackground)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(date.shortFormatted), balance: \(balance?.currencyFormatted ?? "unknown")")
    }
}
