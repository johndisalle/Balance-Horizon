// MainTabView.swift — Balance Horizon
// Primary navigation: tab bar with Calendar, Transactions, Trends, Recurring, and Settings.

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showQuickAdd = false

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

            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.bar.fill")
                }
                .tag(2)

            RecurringListView()
                .tabItem {
                    Label("Recurring", systemImage: "repeat")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .tint(.blue)
        .onOpenURL { url in
            // Handle deep links from widgets
            if url.scheme == "balancehorizon" {
                if url.host == "quickadd" {
                    showQuickAdd = true
                } else if url.host == "today" {
                    selectedTab = 0
                }
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .presentationDetents([.medium])
        }
    }
}
