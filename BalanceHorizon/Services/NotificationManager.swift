// NotificationManager.swift — Balance Horizon
// Smart local notification manager: morning balance updates, low-balance warnings,
// and daily check-in reminders. All local, zero network calls.

import Foundation
import UserNotifications

@Observable
final class NotificationManager {

    // MARK: - State

    private(set) var isAuthorized = false

    private let center = UNUserNotificationCenter.current()
    private let lowBalancePrefix = "lowbalance-"
    private let dailyCheckinID = "daily-checkin"
    private let morningBalanceID = "morning-balance"

    // MARK: - Permission

    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - Morning Balance Notification (Retention Driver)

    /// Schedules a daily 8 AM notification: "Good morning! Your balance today is $X,XXX."
    /// Updates each time the app computes projections so the amount stays current.
    func scheduleMorningBalance(balance: Double) async {
        center.removePendingNotificationRequests(withIdentifiers: [morningBalanceID])

        let formatted = formatCurrency(balance)

        let content = UNMutableNotificationContent()
        content.title = "Good morning!"
        content.sound = .default

        if balance < 0 {
            content.body = "Your balance today is \(formatted). You may want to review upcoming expenses."
        } else if balance < 100 {
            content.body = "Your balance today is \(formatted). Things are getting tight — check your calendar."
        } else {
            content.body = "Your balance today is \(formatted). You're looking good!"
        }

        // Fire every day at 8:00 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: morningBalanceID, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            // Best-effort
        }
    }

    // MARK: - Low-Balance Warnings

    func scheduleLowBalanceWarnings(dayBalances: [Date: Double], threshold: Double) async {
        let pending = await center.pendingNotificationRequests()
        let oldIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(lowBalancePrefix) }
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let horizon = calendar.date(byAdding: .day, value: 30, to: today)!

        let relevantDays: [(Date, Double)] = dayBalances
            .filter { $0.key >= today && $0.key <= horizon }
            .sorted { $0.key < $1.key }

        var previouslyAbove = true
        var crossingIndex = 0

        for (date, balance) in relevantDays {
            let isBelow = balance < threshold
            if isBelow && previouslyAbove {
                let daysFromNow = calendar.dateComponents([.day], from: today, to: date).day ?? 0
                let formattedBalance = formatCurrency(balance)
                let formattedDate = date.formatted(.dateTime.month().day())

                let content = UNMutableNotificationContent()
                content.title = "Balance Alert"
                content.body = "Heads up: Your balance drops to \(formattedBalance) in \(daysFromNow) days (\(formattedDate))."
                content.sound = .default

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
                } catch {}

                crossingIndex += 1
            }
            previouslyAbove = !isBelow
        }
    }

    // MARK: - Daily Check-In Reminder

    func scheduleRecurringReminder() async {
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
        } catch {}
    }

    // MARK: - Cancel All

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
