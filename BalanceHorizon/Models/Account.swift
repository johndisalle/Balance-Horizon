// Account.swift — Balance Horizon
// Multi-account support model for tracking balances across different account types.

import Foundation
import SwiftData

/// The type of financial account
enum AccountType: String, Codable, CaseIterable, Identifiable {
    case checking = "Checking"
    case savings = "Savings"
    case creditCard = "Credit Card"
    case cash = "Cash"

    var id: String { rawValue }
}

@Model
final class Account {
    var id: UUID
    var name: String
    var type: AccountType
    var balance: Double
    var color: String
    var icon: String
    var isDefault: Bool
    var createdAt: Date

    init(
        name: String = "Main Account",
        type: AccountType = .checking,
        balance: Double = 0,
        color: String = "#007AFF",
        icon: String = "building.columns",
        isDefault: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.balance = balance
        self.color = color
        self.icon = icon
        self.isDefault = isDefault
        self.createdAt = .now
    }

    /// Returns a default set of accounts for first launch
    static var defaultAccounts: [Account] {
        [Account(name: "Main Account", type: .checking, balance: 0, color: "#007AFF", icon: "building.columns", isDefault: true)]
    }
}
