// NotificationManager.swift — Balance Horizon
// Smart local notification manager for low-balance warnings and daily check-in reminders.
// All local, zero network calls. Uses UserNotifications framework for iOS 17+.

import Foundation
import UserNotifications

@Observable
final class NotificationManager {

    // MARK: - State

    private(set) var isAuthorized = false

    private let center = UNUserNotificationCenter.current()
    private let lowBalancePrefix = "lowbalance-"
    private let dailyCheckinID = "daily-checkin"

    // MARK: - Permission

    /// Request notification authorization for alerts, badges, and sounds.
    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - Low-Balance Warnings

    /// Scans projected balances for the next 30 days. When the balance crosses below
    /// the given threshold, schedules a single local notification for that crossing.
    /// Removes all previously scheduled low-balance notifications first.
    ///
    /// - Parameters:
    ///   - dayBalances: A dictionary mapping dates to projected balance values.
    ///   - threshold: The dollar amount below which a warning fires.
    func scheduleLowBalanceWarnings(dayBalances: [Date: Double], threshold: Double) async {
        // Remove old low-balance notifications
        let pending = await center.pendingNotificationRequests()
        let oldIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(lowBalancePrefix) }
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Build sorted day list for the next 30 days
        let horizon = calendar.date(byAdding: .day, value: 30, to: today)!
        let relevantDays: [(Date, Double)] = dayBalances
            .filter { $0.key >= today && $0.key <= horizon }
            .sorted { $0.key < $1.key }

        // Walk through days and find threshold crossings
        var previouslyAbove = true
        var crossingIndex = 0

        for (date, balance) in relevantDays {
            let isBelow = balance < threshold
            if isBelow && previouslyAbove {
                // Threshold crossing detected — schedule one notification
                let daysFromNow = calendar.dateComponents([.day], from: today, to: date).day ?? 0
                let formattedBalance = String(format: "$%.2f", balance)
                let formattedDate = date.formatted(.dateTime.month().day())

                let content = UNMutableNotificationContent()
                content.title = "Low Balance Warning"
                content.body = "Heads up: Your balance drops to \(formattedBalance) in \(daysFromNow) days (\(formattedDate))."
                content.sound = .default

                // Schedule for 8 AM on the day before the crossing, or now+5s if it is today/tomorrow
                let triggerDate: Date
                if daysFromNow <= 1 {
                    triggerDate = Date.now.addingTimeInterval(5)
                } else {
                    let dayBefore = calendar.date(byAdding: .day, value: -1, to: date)!
                    var components = calendar.dateComponents([.year, .month, .day], from: dayBefore)
                    components.hour = 8
                    components.minute = 0
                    triggerDate = calendar.date(from: components) ?? Date.now.addingTimeInterval(5)
                }

                let triggerComponents = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: triggerDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

                let identifier = "\(lowBalancePrefix)\(crossingIndex)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                do {
                    try await center.add(request)
                } catch {
                    // Silently fail — notification scheduling is best-effort
                }

                crossingIndex += 1
            }
            previouslyAbove = !isBelow
        }
    }

    // MARK: - Daily Check-In Reminder

    /// Schedules a repeating daily reminder at 9:00 AM to check the balance.
    func scheduleRecurringReminder() async {
        // Remove any existing daily check-in first
        center.removePendingNotificationRequests(withIdentifiers: [dailyCheckinID])

        let content = UNMutableNotificationContent()
        content.title = "Balance Horizon"
        content.body = "Good morning! Take a moment to check your projected balance."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: dailyCheckinID, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            // Best-effort scheduling
        }
    }

    // MARK: - Cancel All

    /// Removes all pending notifications managed by this app.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
