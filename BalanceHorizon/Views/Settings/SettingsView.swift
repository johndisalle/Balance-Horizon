// SettingsView.swift — Balance Horizon
// App settings: starting balance, category editor, premium status, data export.

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArray: [AppSettings]
    @Environment(\.modelContext) private var context

    @State private var showingCategoryEditor = false
    @State private var showingPaywall = false
    @State private var editingBalance: String = ""
    @State private var showBalanceEditor = false

    private var settings: AppSettings? { settingsArray.first }

    var body: some View {
        NavigationStack {
            List {
                // Balance section
                Section("Starting Balance") {
                    HStack {
                        Text("Current Starting Balance")
                        Spacer()
                        Text(settings?.startingBalance.currencyFormatted ?? "$0.00")
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture { showBalanceEditor = true }

                    if let date = settings?.startingBalanceDate {
                        HStack {
                            Text("Balance Date")
                            Spacer()
                            Text(date.shortFormatted)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Categories
                Section("Categories") {
                    Button {
                        showingCategoryEditor = true
                    } label: {
                        HStack {
                            Text("Edit Categories")
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

                // Premium
                Section("Premium") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(settings?.isPremium == true ? "Premium" : "Free")
                            .foregroundStyle(settings?.isPremium == true ? .green : .secondary)
                    }

                    if settings?.isPremium != true {
                        Button("Upgrade to Premium") {
                            showingPaywall = true
                        }
                        .foregroundStyle(.blue)
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Privacy")
                        Spacer()
                        Text("100% Offline")
                            .foregroundStyle(.green)
                    }
                }

                // Data (Premium)
                if settings?.isPremium == true {
                    Section("Data") {
                        Button("Export CSV") { exportCSV() }
                        Button("Export PDF Report") { exportPDF() }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingCategoryEditor) {
                CategoryEditorView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .alert("Edit Starting Balance", isPresented: $showBalanceEditor) {
                TextField("Balance", text: $editingBalance)
                    .keyboardType(.decimalPad)
                Button("Save") {
                    if let val = Double(editingBalance.replacingOccurrences(of: ",", with: ".")) {
                        settings?.startingBalance = val
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

    // Placeholder implementations for premium features
    private func exportCSV() {
        // TODO: Implement CSV export with UIActivityViewController
    }

    private func exportPDF() {
        // TODO: Implement PDF report generation
    }
}
