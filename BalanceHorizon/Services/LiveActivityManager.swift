// LiveActivityManager.swift — Balance Horizon
// Manages Live Activities for showing current balance on the lock screen.

import ActivityKit
import Foundation
import SwiftUI

/// Attributes for the Balance Horizon Live Activity
struct BalanceAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentBalance: Double
        var nextChangeAmount: Double
        var nextChangeDate: Date
        var nextChangeDescription: String
    }
}

/// Manages the lifecycle of a Live Activity displaying the user's current balance
/// and next upcoming transaction.
@Observable
class LiveActivityManager {

    private var currentActivity: Activity<BalanceAttributes>?

    /// Whether a Live Activity is currently running
    var isActivityActive: Bool {
        currentActivity != nil
    }

    /// Starts a new Live Activity showing the current balance and optional next transaction.
    func startActivity(balance: Double, nextChange: (amount: Double, date: Date, desc: String)?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        // End any existing activity before starting a new one
        if currentActivity != nil {
            endActivity()
        }

        let state = BalanceAttributes.ContentState(
            currentBalance: balance,
            nextChangeAmount: nextChange?.amount ?? 0,
            nextChangeDate: nextChange?.date ?? .distantFuture,
            nextChangeDescription: nextChange?.desc ?? ""
        )

        let attributes = BalanceAttributes()
        let content = ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .hour, value: 1, to: .now))

        do {
            currentActivity = try Activity<BalanceAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            currentActivity = nil
        }
    }

    /// Updates the existing Live Activity with new balance and next transaction info.
    func updateActivity(balance: Double, nextChange: (amount: Double, date: Date, desc: String)?) {
        guard let activity = currentActivity else {
            return
        }

        let state = BalanceAttributes.ContentState(
            currentBalance: balance,
            nextChangeAmount: nextChange?.amount ?? 0,
            nextChangeDate: nextChange?.date ?? .distantFuture,
            nextChangeDescription: nextChange?.desc ?? ""
        )

        let content = ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .hour, value: 1, to: .now))

        Task {
            await activity.update(content)
        }
    }

    /// Ends the current Live Activity.
    func endActivity() {
        guard let activity = currentActivity else {
            return
        }

        let finalState = BalanceAttributes.ContentState(
            currentBalance: 0,
            nextChangeAmount: 0,
            nextChangeDate: .distantFuture,
            nextChangeDescription: ""
        )

        let content = ActivityContent(state: finalState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .immediate)
        }

        currentActivity = nil
    }
}
