// CategoryIconsView.swift — Balance Horizon
// Smart category icons that replace the plain blue dot on calendar day cells.
// Shows up to 3 tiny SF Symbol icons color-coded by category, plus an
// income/expense split indicator when a day has both types.

import SwiftUI

struct CategoryIconsView: View {
    let transactions: [Transaction]

    private var uniqueCategories: [String] {
        var seen = Set<String>()
        var result = [String]()
        for t in transactions {
            if seen.insert(t.category).inserted {
                result.append(t.category)
            }
        }
        return result
    }

    private var hasBothTypes: Bool {
        let types = Set(transactions.map(\.type))
        return types.contains(.income) && types.contains(.expense)
    }

    var body: some View {
        HStack(spacing: 2) {
            if hasBothTypes {
                splitIndicator
            }

            if uniqueCategories.count <= 3 {
                ForEach(uniqueCategories, id: \.self) { category in
                    Image(systemName: Self.icon(for: category))
                        .font(.system(size: 8))
                        .foregroundStyle(Self.color(for: category))
                }
            } else {
                ForEach(uniqueCategories.prefix(2), id: \.self) { category in
                    Image(systemName: Self.icon(for: category))
                        .font(.system(size: 8))
                        .foregroundStyle(Self.color(for: category))
                }
                Text("+\(uniqueCategories.count - 2)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 12)
    }

    private var splitIndicator: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(.green)
                .frame(width: 4, height: 4)
            Circle()
                .fill(.red)
                .frame(width: 4, height: 4)
                .offset(x: -1)
        }
    }

    // MARK: - Static Helpers

    static func icon(for category: String) -> String {
        switch category {
        case "Salary":        return "banknote"
        case "Rent":          return "house"
        case "Groceries":     return "cart"
        case "Utilities":     return "bolt.fill"
        case "Transport":     return "car"
        case "Dining":        return "fork.knife"
        case "Entertainment": return "gamecontroller"
        case "Health":        return "heart"
        case "Shopping":      return "bag"
        case "Subscriptions": return "repeat.circle"
        case "Savings":       return "leaf"
        case "Gifts":         return "gift"
        case "Education":     return "graduationcap"
        case "Travel":        return "airplane"
        case "Bills":         return "doc.text"
        case "Coffee":        return "cup.and.saucer"
        default:              return "circle.fill"
        }
    }

    static func color(for category: String) -> Color {
        switch category {
        case "Salary":        return .green
        case "Rent":          return .orange
        case "Groceries":     return .green
        case "Utilities":     return .yellow
        case "Transport":     return .blue
        case "Dining":        return .orange
        case "Entertainment": return .purple
        case "Health":        return .red
        case "Shopping":      return .pink
        case "Subscriptions": return .cyan
        case "Savings":       return .mint
        case "Gifts":         return .red
        case "Education":     return .indigo
        case "Travel":        return .teal
        case "Bills":         return .gray
        case "Coffee":        return .brown
        default:              return .secondary
        }
    }
}
