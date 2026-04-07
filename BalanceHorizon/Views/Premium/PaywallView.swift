// PaywallView.swift — Balance Horizon
// Premium paywall with StoreKit 2. Three tiers: Monthly ($4.99), Yearly ($29.99),
// Lifetime ($79.99). Shows feature list, animated header, and restore button.

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeManager = StoreKitManager()
    @State private var selectedPlan: String? = ProductID.yearlyPremium
    @State private var purchaseSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    pricingSection
                    trialNote
                    restoreAndLegal
                }
            }
            .background(Color.secondaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay {
                if purchaseSuccess {
                    successOverlay
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.yellow.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow)
                    .symbolEffect(.pulse)
            }

            Text("Go Premium")
                .font(.largeTitle.weight(.bold))

            Text("Unlock widgets, multi-account,\nexports, and more")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FeatureRow(icon: "rectangle.3.group.fill", title: "Home Screen Widgets", description: "7-day balance forecast at a glance")
            FeatureRow(icon: "building.columns.fill", title: "Multiple Accounts", description: "Track checking, savings, and credit cards")
            FeatureRow(icon: "doc.text.fill", title: "CSV Import & Export", description: "Move your data freely")
            FeatureRow(icon: "doc.richtext.fill", title: "PDF Monthly Reports", description: "Beautiful printable summaries")
            FeatureRow(icon: "chart.bar.fill", title: "Advanced Trends", description: "12+ month projections and insights")
            FeatureRow(icon: "applewatch", title: "Apple Watch App", description: "Balance on your wrist")
            FeatureRow(icon: "icloud.fill", title: "iCloud Sync", description: "Seamless across all your devices")
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Pricing Cards

    private var pricingSection: some View {
        VStack(spacing: 10) {
            // Yearly (recommended)
            PricingTierCard(
                title: "Yearly",
                price: storeManager.yearlyProduct?.displayPrice ?? "$29.99",
                subtitle: "per year",
                badge: "Best Value — Save 50%",
                isSelected: selectedPlan == ProductID.yearlyPremium,
                isLoading: storeManager.isLoading
            ) {
                selectedPlan = ProductID.yearlyPremium
            } onPurchase: {
                await purchaseSelected()
            }

            // Monthly
            PricingTierCard(
                title: "Monthly",
                price: storeManager.monthlyProduct?.displayPrice ?? "$4.99",
                subtitle: "per month",
                badge: nil,
                isSelected: selectedPlan == ProductID.monthlyPremium,
                isLoading: storeManager.isLoading
            ) {
                selectedPlan = ProductID.monthlyPremium
            } onPurchase: {
                await purchaseSelected()
            }

            // Lifetime
            PricingTierCard(
                title: "Lifetime",
                price: storeManager.lifetimeProduct?.displayPrice ?? "$79.99",
                subtitle: "one-time purchase",
                badge: "Pay Once, Own Forever",
                isSelected: selectedPlan == ProductID.lifetimePremium,
                isLoading: storeManager.isLoading
            ) {
                selectedPlan = ProductID.lifetimePremium
            } onPurchase: {
                await purchaseSelected()
            }

            // Purchase button
            Button {
                Task { await purchaseSelected() }
            } label: {
                Group {
                    if storeManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Continue")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
            }
            .disabled(storeManager.isLoading || selectedPlan == nil)
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
    }

    private var trialNote: some View {
        Text("Start with a 3-day free trial. Cancel anytime.")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
    }

    private var restoreAndLegal: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Task { await storeManager.restorePurchases() }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text("Payment will be charged to your Apple ID account. Subscription automatically renews unless turned off at least 24 hours before the end of the current period. Lifetime purchase is non-refundable.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://johndisalle.github.io/Balance-Horizon/privacy-policy")!)
                Text("·").foregroundStyle(.tertiary)
                Link("Terms of Service", destination: URL(string: "https://johndisalle.github.io/Balance-Horizon/terms-of-service")!)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.bottom, 20)
        }
    }

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Welcome to Premium!")
                .font(.title2.weight(.bold))
            Text("All features are now unlocked.")
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .font(.headline)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .transition(.opacity)
    }

    private func purchaseSelected() async {
        guard let plan = selectedPlan,
              let product = storeManager.products.first(where: { $0.id == plan }) else { return }
        let success = await storeManager.purchase(product)
        if success {
            withAnimation { purchaseSuccess = true }
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Pricing Tier Card

struct PricingTierCard: View {
    let title: String
    let price: String
    let subtitle: String
    let badge: String?
    let isSelected: Bool
    let isLoading: Bool
    let onTap: () -> Void
    let onPurchase: () async -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(price)
                    .font(.title3.weight(.bold))

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
