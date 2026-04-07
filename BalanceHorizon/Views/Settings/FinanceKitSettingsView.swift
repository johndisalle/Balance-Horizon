// FinanceKitSettingsView.swift — Balance Horizon
// Settings sub-view for Apple Wallet (FinanceKit) transaction import.

import SwiftUI
import SwiftData

struct FinanceKitSettingsView: View {
    @State private var financeKitManager = FinanceKitManager()
    @Environment(\.modelContext) private var modelContext

    @State private var isSyncing = false
    @State private var showSuccess = false
    @State private var syncError: String?

    var body: some View {
        List {
            statusSection
            if financeKitManager.isAvailable {
                if financeKitManager.isAuthorized {
                    syncSection
                } else {
                    connectSection
                }
            } else {
                unavailableSection
            }
            privacySection
        }
        .navigationTitle("Apple Wallet Import")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await financeKitManager.requestAuthorization()
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(statusColor.gradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: statusIcon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Wallet")
                        .font(.headline)
                    Text(statusLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
            }
            .padding(.vertical, 4)
        }
    }

    private var statusColor: Color {
        if !financeKitManager.isAvailable { return .gray }
        return financeKitManager.isAuthorized ? .green : .orange
    }

    private var statusIcon: String {
        if !financeKitManager.isAvailable { return "wallet.pass" }
        return financeKitManager.isAuthorized ? "checkmark.shield.fill" : "wallet.pass"
    }

    private var statusLabel: String {
        if !financeKitManager.isAvailable { return "Not Available" }
        return financeKitManager.isAuthorized ? "Connected" : "Not Connected"
    }

    // MARK: - Connect

    private var connectSection: some View {
        Section {
            Button {
                Task {
                    await financeKitManager.requestAuthorization()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "wallet.pass.fill")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connect Apple Wallet")
                            .font(.body.weight(.semibold))
                        Text("Import transactions automatically")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 8)
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.blue.gradient)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 2)
            )
        } header: {
            Text("Get Started")
        } footer: {
            Text("Balance Horizon will request read-only access to your Apple Wallet transactions.")
                .font(.caption)
        }
    }

    // MARK: - Sync

    private var syncSection: some View {
        Section {
            // Last sync info
            if let lastSync = financeKitManager.lastSyncDate {
                HStack {
                    Label("Last synced", systemImage: "clock.arrow.circlepath")
                    Spacer()
                    Text(lastSync, style: .relative)
                        .foregroundStyle(.secondary)
                        .font(.subheadline.monospacedDigit())
                    Text("ago")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }

            // Sync button
            Button {
                performSync()
            } label: {
                HStack {
                    Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        .font(.body.weight(.medium))
                    Spacer()
                    if isSyncing {
                        ProgressView()
                    }
                }
            }
            .disabled(isSyncing)

            // Success message
            if showSuccess {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Import Complete")
                            .font(.subheadline.weight(.semibold))
                        Text("Imported \(financeKitManager.importedCount) new transaction\(financeKitManager.importedCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Error message
            if let error = syncError {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sync Failed")
                            .font(.subheadline.weight(.semibold))
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Sync Transactions")
        } footer: {
            Text("Transactions from Apple Wallet are matched to avoid duplicates.")
                .font(.caption)
        }
    }

    // MARK: - Unavailable

    private var unavailableSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "iphone.slash")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Not Available")
                        .font(.body.weight(.medium))
                    Text("Apple Wallet import requires iOS 17+ on a physical device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Data Stays on Device")
                        .font(.subheadline.weight(.semibold))
                    Text("Transactions are read from Apple Wallet and stored only on this device. No data is sent anywhere.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 6)
        } header: {
            Text("Privacy")
        }
    }

    // MARK: - Actions

    private func performSync() {
        isSyncing = true
        showSuccess = false
        syncError = nil

        Task {
            do {
                let count = try await financeKitManager.importTransactions(context: modelContext)
                isSyncing = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccess = true
                }
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(count > 0 ? .success : .warning)
            } catch {
                isSyncing = false
                syncError = error.localizedDescription
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
}
