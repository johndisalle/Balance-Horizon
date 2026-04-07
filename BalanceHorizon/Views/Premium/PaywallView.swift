// PaywallView.swift — Balance Horizon
// Premium paywall with StoreKit 2 integration. Displays subscription tiers,
// feature list, and restore purchases button.

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeManager = StoreKitManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.yellow)
                            .symbolEffect(.bounce)

                        Text("Balance Horizon Premium")
                            .font(.title.weight(.bold))

                        Text("Unlock the full experience")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "doc.text", title: "CSV Import & Export", description: "Move data in and out freely")
                        FeatureRow(icon: "building.columns", title: "Multiple Accounts", description: "Track checking, savings, credit")
                        FeatureRow(icon: "doc.richtext", title: "PDF Monthly Reports", description: "Beautiful printable summaries")
                        FeatureRow(icon: "rectangle.3.group", title: "Home Screen Widgets", description: "7-day balance at a glance")
                        FeatureRow(icon: "icloud", title: "iCloud Sync", description: "Sync across all your devices")
                    }
                    .padding(.horizontal)

                    // Pricing
                    VStack(spacing: 12) {
                        ForEach(storeManager.products) { product in
                            PricingCard(product: product) {
                                Task { await storeManager.purchase(product) }
                            }
                        }

                        // Fallback if products haven't loaded
                        if storeManager.products.isEmpty {
                            PricingCardPlaceholder(
                                title: "Monthly",
                                price: "$3.99/mo"
                            )
                            PricingCardPlaceholder(
                                title: "Yearly",
                                price: "$29.99/yr",
                                badge: "Save 37%"
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Restore
                    Button("Restore Purchases") {
                        Task { await storeManager.restorePurchases() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                    // Legal
                    Text("Payment will be charged to your Apple ID account. Subscription automatically renews unless turned off at least 24 hours before the end of the current period.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
            }
            .background(Color.secondaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
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

// MARK: - Pricing Card

struct PricingCard: View {
    let product: Product
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.title3.weight(.bold))
            }
            .padding()
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.blue, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

struct PricingCardPlaceholder: View {
    let title: String
    let price: String
    var badge: String? = nil

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title).font(.headline)
                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
            }
            Spacer()
            Text(price)
                .font(.title3.weight(.bold))
        }
        .padding()
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.blue.opacity(0.5), lineWidth: 1))
    }
}
