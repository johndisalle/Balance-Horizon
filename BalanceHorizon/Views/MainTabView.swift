// MainTabView.swift — Balance Horizon
// Primary navigation: tab bar with Calendar, Transactions, Recurring, and Settings tabs.

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(0)

            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            RecurringListView()
                .tabItem {
                    Label("Recurring", systemImage: "repeat")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}
