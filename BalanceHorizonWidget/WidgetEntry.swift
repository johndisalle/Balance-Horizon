import WidgetKit
import Foundation

// MARK: - Trend Direction

enum TrendDirection: String {
    case up
    case down
    case flat

    var symbolName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }
}

// MARK: - WeekDay

struct WeekDay: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double

    var dayAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Timeline Entry

struct BalanceWidgetEntry: TimelineEntry {
    let date: Date
    let todayBalance: Double
    let weekBalances: [WeekDay]
    let trendDirection: TrendDirection

    static var placeholder: BalanceWidgetEntry {
        let calendar = Calendar.current
        let today = Date()
        let weekBalances = (0..<7).map { offset in
            WeekDay(
                date: calendar.date(byAdding: .day, value: offset, to: today)!,
                balance: Double.random(in: 50...500)
            )
        }
        return BalanceWidgetEntry(
            date: today,
            todayBalance: 247.50,
            weekBalances: weekBalances,
            trendDirection: .up
        )
    }
}
