# Balance Horizon

A calendar-centric budgeting app for iOS — see your balance tomorrow, today.

## Overview

Balance Horizon is a privacy-first, offline-only budgeting app inspired by EasyBudget's simplicity but built with modern SwiftUI. It shows projected daily balances on an interactive calendar, making it effortless to see how your finances look days, weeks, or months ahead.

## Features

### Free Tier
- **Interactive Monthly Calendar** — Color-coded daily balances (green/orange/red)
- **Balance Projections** — Forward-running balance calculated from recurring + one-time transactions
- **Recurring Transactions** — Daily, weekly, bi-weekly, monthly, quarterly, yearly
- **Swift Charts** — Monthly balance trend line
- **Full Dark Mode** — Dynamic colors throughout
- **100% Offline** — Zero network calls, complete privacy
- **Accessibility** — VoiceOver labels, Dynamic Type support

### Premium ($3.99/mo or $29.99/yr)
- CSV Import/Export
- Multiple Accounts
- PDF Monthly Reports
- Home Screen Widgets
- iCloud Sync

## Architecture

- **SwiftData** (iOS 17+) for persistence
- **MVVM** with `@Observable` view models
- **Pure SwiftUI** — no UIKit dependencies except haptics
- **ProjectionEngine** — rule-based daily balance calculator
- **StoreKit 2** for premium subscriptions

## Project Structure

```
BalanceHorizon/
├── BalanceHorizonApp.swift          # App entry point + routing
├── Models/
│   ├── Transaction.swift            # Core transaction model
│   └── AppSettings.swift            # User preferences
├── ViewModels/
│   └── CalendarViewModel.swift      # Calendar state + projections
├── Views/
│   ├── MainTabView.swift            # Tab navigation
│   ├── Calendar/
│   │   ├── CalendarView.swift       # Main calendar screen
│   │   ├── DayCell.swift            # Individual day cell
│   │   └── DayDetailSheet.swift     # Day tap detail modal
│   ├── Transactions/
│   │   ├── AddTransactionView.swift # Add/edit form
│   │   └── TransactionListView.swift# Filterable list
│   ├── Recurring/
│   │   └── RecurringListView.swift  # Manage recurring rules
│   ├── Onboarding/
│   │   └── OnboardingView.swift     # First-launch walkthrough
│   ├── Settings/
│   │   ├── SettingsView.swift       # App settings
│   │   └── CategoryEditorView.swift # Custom categories
│   └── Premium/
│       └── PaywallView.swift        # Subscription paywall
├── Services/
│   ├── ProjectionEngine.swift       # Balance calculation engine
│   └── StoreKitManager.swift        # StoreKit 2 integration
└── Extensions/
    └── Extensions.swift             # Currency formatting, date helpers
```

## Requirements

- iOS 17.0+
- Xcode 16.0+
- Swift 5.9+

## Setup

1. Open `BalanceHorizon.xcodeproj` in Xcode
2. Set your development team and bundle identifier
3. Configure StoreKit product IDs in `StoreKitManager.swift`
4. Build and run

## Bundle ID

`com.ellasid.balancehorizon`

## Privacy

Balance Horizon makes **zero network calls** in the free tier. All data is stored locally using SwiftData. Premium iCloud sync is opt-in only.
