// SettingsView.swift — Balance Horizon
// App settings: starting balance, accounts, categories, notifications,
// premium status, CSV/PDF export, and privacy info.

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArray: [AppSettings]
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Query private var accounts: [Account]
    @Environment(\.modelContext) private var context

    @State private var showingCategoryEditor = false
    @State private var showingPaywall = false
    @State private var showingAccountEditor = false
    @State private var showingThemePicker = false
    @State private var editingBalance: String = ""
    @State private var showBalanceEditor = false
    @State private var showShareSheet = false
    @State private var exportFileURL: URL?

    private var settings: AppSettings? { settingsArray.first }

    var body: some View {
        NavigationStack {
            List {
                balanceSection
                accountsSection
                categoriesSection
                appearanceSection
                notificationsSection
                moreSection
                premiumSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingCategoryEditor) {
                CategoryEditorView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingAccountEditor) {
                AccountEditorView()
            }
            .sheet(isPresented: $showingThemePicker) {
                ThemePickerView()
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Edit Starting Balance", isPresented: $showBalanceEditor) {
                TextField("Balance", text: $editingBalance)
                    .keyboardType(.decimalPad)
                Button("Save") {
                    if let val = Double(editingBalance.replacingOccurrences(of: ",", with: ".")) {
                        settings?.startingBalance = val
                        let gen = UINotificationFeedbackGenerator()
                        gen.notificationOccurred(.success)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your current account balance")
            }
            .onAppear {
                editingBalance = String(format: "%.2f", settings?.startingBalance ?? 0)
            }
        }
    }

    // MARK: - Sections

    private var balanceSection: some View {
        Section("Starting Balance") {
            HStack {
                Label("Current Balance", systemImage: "banknote")
                Spacer()
                Text(settings?.startingBalance.currencyFormatted ?? "$0.00")
                    .foregroundStyle(.secondary)
                    .font(.body.monospacedDigit())
            }
            .contentShape(Rectangle())
            .onTapGesture { showBalanceEditor = true }

            if let date = settings?.startingBalanceDate {
                HStack {
                    Label("Balance Date", systemImage: "calendar")
                    Spacer()
                    Text(date.shortFormatted)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var accountsSection: some View {
        Section("Accounts") {
            if settings?.isPremium == true {
                ForEach(accounts, id: \.id) { account in
                    HStack {
                        Image(systemName: account.icon)
                            .foregroundStyle(.blue)
                        Text(account.name)
                        Spacer()
                        Text(account.balance.currencyFormatted)
                            .foregroundStyle(.secondary)
                            .font(.body.monospacedDigit())
                    }
                }
                Button {
                    showingAccountEditor = true
                } label: {
                    Label("Manage Accounts", systemImage: "plus.circle")
                }
            } else {
                HStack {
                    Label("Multiple Accounts", systemImage: "building.columns")
                    Spacer()
                    premiumBadge
                }
                .onTapGesture { showingPaywall = true }
            }
        }
    }

    private var categoriesSection: some View {
        Section("Categories") {
            Button {
                showingCategoryEditor = true
            } label: {
                HStack {
                    Label("Edit Categories", systemImage: "tag")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(settings?.categories.count ?? 0)")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Button {
                showingThemePicker = true
            } label: {
                HStack {
                    Label("Theme & App Icon", systemImage: "paintbrush")
                        .foregroundStyle(.primary)
                    Spacer()
                    if settings?.isPremium != true {
                        Text("PRO")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var moreSection: some View {
        Section("More") {
            NavigationLink {
                RecurringListView()
            } label: {
                Label("Recurring Transactions", systemImage: "repeat")
            }
            NavigationLink {
                TrendsView()
            } label: {
                Label("Spending Trends", systemImage: "chart.bar.fill")
            }
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: Binding(
                get: { settings?.lowBalanceAlertsEnabled ?? true },
                set: { settings?.lowBalanceAlertsEnabled = $0 }
            )) {
                Label("Low Balance Alerts", systemImage: "bell.badge")
            }

            if settings?.lowBalanceAlertsEnabled == true {
                HStack {
                    Label("Threshold", systemImage: "exclamationmark.triangle")
                    Spacer()
                    Text(settings?.lowBalanceThreshold.currencyFormatted ?? "$100.00")
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: Binding(
                get: { settings?.dailyReminderEnabled ?? false },
                set: { settings?.dailyReminderEnabled = $0 }
            )) {
                Label("Daily Reminder (9 AM)", systemImage: "clock")
            }
        }
    }

    private var premiumSection: some View {
        Section("Premium") {
            HStack {
                Label("Status", systemImage: "crown")
                Spacer()
                Text(settings?.premiumTier.rawValue ?? "Free")
                    .foregroundStyle(settings?.isPremium == true ? .green : .secondary)
                    .font(.body.weight(.medium))
            }

            if settings?.isPremium != true {
                Button {
                    showingPaywall = true
                } label: {
                    HStack {
                        Text("Upgrade to Premium")
                            .font(.body.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.blue)
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            if settings?.isPremium == true {
                Button {
                    exportCSV()
                } label: {
                    Label("Export Transactions (CSV)", systemImage: "doc.text")
                        .foregroundStyle(.primary)
                }

                Button {
                    exportMonthlyCSV()
                } label: {
                    Label("Export Monthly Report (CSV)", systemImage: "doc.richtext")
                        .foregroundStyle(.primary)
                }
            } else {
                HStack {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                    Spacer()
                    premiumBadge
                }
                .onTapGesture { showingPaywall = true }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("Privacy", systemImage: "lock.shield")
                Spacer()
                Text("100% Offline")
                    .foregroundStyle(.green)
                    .font(.body.weight(.medium))
            }
        }
    }

    private var premiumBadge: some View {
        Text("PRO")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.blue, in: Capsule())
            .foregroundStyle(.white)
    }

    // MARK: - Export

    private func exportCSV() {
        let csv = CSVExporter.exportTransactions(transactions)
        if let url = CSVExporter.generateTemporaryFile(csv: csv, filename: "balance-horizon-transactions.csv") {
            exportFileURL = url
            showShareSheet = true
        }
    }

    private func exportMonthlyCSV() {
        let csv = CSVExporter.exportMonthlyReport(
            transactions: transactions,
            month: .now,
            startingBalance: settings?.startingBalance ?? 0
        )
        if let url = CSVExporter.generateTemporaryFile(csv: csv, filename: "balance-horizon-monthly-report.csv") {
            exportFileURL = url
            showShareSheet = true
        }
    }
}

// MARK: - Share Sheet (UIKit bridge)

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Account Editor

struct AccountEditorView: View {
    @Query private var accounts: [Account]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""
    @State private var newType: AccountType = .checking

    var body: some View {
        NavigationStack {
            List {
                Section("Add Account") {
                    TextField("Account name", text: $newName)
                    Picker("Type", selection: $newType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    Button("Add") {
                        guard !newName.isEmpty else { return }
                        let account = Account()
                        account.name = newName
                        account.type = newType
                        account.isDefault = accounts.isEmpty
                        context.insert(account)
                        newName = ""
                    }
                    .disabled(newName.isEmpty)
                }

                Section("Accounts") {
                    ForEach(accounts, id: \.id) { account in
                        HStack {
                            Image(systemName: account.icon)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(account.name).font(.body.weight(.medium))
                                Text(account.type.rawValue.capitalized)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if account.isDefault {
                                Text("Default")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets { context.delete(accounts[i]) }
                    }
                }
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
