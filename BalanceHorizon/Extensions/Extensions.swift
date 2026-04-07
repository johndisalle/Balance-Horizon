// Extensions.swift — Balance Horizon
// Shared utility extensions for Date formatting, currency display, Color helpers,
// and accessibility support.

import SwiftUI

// MARK: - Double Currency Formatting

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

// MARK: - Date Helpers

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

    var dayOfWeekShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    var monthYearFormatted: String {
        formatted(.dateTime.month(.wide).year())
    }
}

// MARK: - Color Helpers

extension Color {
    static let balanceGreen = Color.green
    static let balanceYellow = Color.orange
    static let balanceRed = Color.red

    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)

    /// Initialize from hex string (e.g., "#007AFF")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 122, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply a spring animation on tap with haptic feedback
    func hapticTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                let gen = UIImpactFeedbackGenerator(style: style)
                gen.impactOccurred()
            }
        )
    }
}
