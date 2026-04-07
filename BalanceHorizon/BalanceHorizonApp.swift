// BalanceHorizonApp.swift — Balance Horizon
// App entry point. Configures SwiftData model container and determines
// whether to show onboarding or the main tab view.

import SwiftUI
import SwiftData

@main
struct BalanceHorizonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentRootView()
        }
        .modelContainer(for: [Transaction.self, AppSettings.self])
    }
}

/// Root view that checks onboarding state and routes accordingly
struct ContentRootView: View {
    @Query private var settingsArray: [AppSettings]
    @Environment(\.modelContext) private var context

    private var settings: AppSettings {
        if let existing = settingsArray.first { return existing }
        let new = AppSettings()
        context.insert(new)
        return new
    }

    var body: some View {
        if settings.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}
