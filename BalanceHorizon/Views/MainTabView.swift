// MainTabView.swift — Balance Horizon
// Primary navigation with 5 tabs: Calendar, Insights, What If, Transactions, Settings.
// Insights and What If replace the old Trends/Recurring tabs as primary navigation,
// with Trends and Recurring accessible from within those screens or Settings.

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

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "sparkles")
                }
                .tag(1)

            WhatIfSimulatorView()
                .tabItem {
                    Label("What If", systemImage: "questionmark.circle")
                }
                .tag(2)

            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
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
            if url.scheme == "balancehorizon" {
                if url.host == "quickadd" {
                    showQuickAdd = true
                } else if url.host == "today" {
                    selectedTab = 0
                } else if url.host == "insights" {
                    selectedTab = 1
                } else if url.host == "whatif" {
                    selectedTab = 2
                }
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .presentationDetents([.medium])
        }
    }
}
