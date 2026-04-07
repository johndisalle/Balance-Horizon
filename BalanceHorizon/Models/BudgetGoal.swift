// BudgetGoal.swift — Balance Horizon
// SwiftData model for monthly budget goals per spending category.
// Tracks limits, icons, and colors; supports progress calculation.

import Foundation
import SwiftData

@Model
final class BudgetGoal {
    var id: UUID
    var category: String
    var monthlyLimit: Double
    var icon: String
    var color: String
    var isActive: Bool
    var createdAt: Date

    init(
        category: String = "General",
        monthlyLimit: Double = 100.0,
        icon: String = "dollarsign.circle",
        color: String = "#007AFF",
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.category = category
        self.monthlyLimit = monthlyLimit
        self.icon = icon
        self.color = color
        self.isActive = isActive
        self.createdAt = .now
    }

    /// Returns progress ratio (0.0...); values above 1.0 indicate over budget.
    func progress(spent: Double) -> Double {
        guard monthlyLimit > 0 else { return 0 }
        return spent / monthlyLimit
    }

    /// Pre-built goal suggestions for common spending categories.
    static var suggestions: [BudgetGoal] {
        [
            BudgetGoal(category: "Dining",        monthlyLimit: 300, icon: "fork.knife",      color: "#FF6B35"),
            BudgetGoal(category: "Groceries",     monthlyLimit: 400, icon: "cart",             color: "#30D158"),
            BudgetGoal(category: "Shopping",      monthlyLimit: 200, icon: "bag",              color: "#AF52DE"),
            BudgetGoal(category: "Entertainment", monthlyLimit: 100, icon: "gamecontroller",   color: "#FF2D55"),
            BudgetGoal(category: "Transport",     monthlyLimit: 150, icon: "car",              color: "#007AFF"),
            BudgetGoal(category: "Coffee",        monthlyLimit:  50, icon: "cup.and.saucer",   color: "#FF9500"),
        ]
    }
}
