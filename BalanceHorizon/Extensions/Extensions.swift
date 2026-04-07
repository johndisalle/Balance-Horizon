// Extensions.swift — Balance Horizon
// Shared utility extensions for Date formatting, currency display, and Color helpers.

import SwiftUI

extension Double {
    /// Format as currency string (e.g., "$1,234.56")
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    /// Compact currency for calendar cells (e.g., "$1.2K")
    var compactCurrency: String {
        let abs = Swift.abs(self)
        let sign = self < 0 ? "-" : ""
        if abs >= 1_000_000 {
            return "\(sign)$\(String(format: "%.1fM", abs / 1_000_000))"
        } else if abs >= 10_000 {
            return "\(sign)$\(String(format: "%.0fK", abs / 1_000))"
        } else if abs >= 1_000 {
            return "\(sign)$\(String(format: "%.1fK", abs / 1_000))"
        }
        return "\(sign)$\(String(format: "%.0f", abs))"
    }
}

extension Date {
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var shortFormatted: String {
        formatted(.dateTime.month(.abbreviated).day().year())
    }
}

extension Color {
    static let balanceGreen = Color.green
    static let balanceYellow = Color.orange
    static let balanceRed = Color.red

    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
}
