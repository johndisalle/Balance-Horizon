// ThemePickerView.swift — Balance Horizon
// Custom themes and app icon picker. Non-default themes require Premium.
// Uses @AppStorage for fast persistence (not SwiftData).

import SwiftUI
import SwiftData

// MARK: - AppTheme Enum

enum AppTheme: String, CaseIterable, Identifiable {
    case default_ = "default"
    case ocean = "ocean"
    case midnight = "midnight"
    case sunset = "sunset"
    case roseGold = "roseGold"
    case emerald = "emerald"
    case slate = "slate"
    case ruby = "ruby"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .default_: return "Default"
        case .ocean:    return "Ocean"
        case .midnight: return "Midnight"
        case .sunset:   return "Sunset"
        case .roseGold: return "Rose Gold"
        case .emerald:  return "Emerald"
        case .slate:    return "Slate"
        case .ruby:     return "Ruby"
        }
    }

    var primaryColor: Color {
        switch self {
        case .default_: return .blue
        case .ocean:    return Color(hex: "0A84FF")
        case .midnight: return Color(hex: "5856D6")
        case .sunset:   return Color(hex: "FF6B35")
        case .roseGold: return Color(hex: "E8A0BF")
        case .emerald:  return Color(hex: "30D158")
        case .slate:    return Color(hex: "8E8E93")
        case .ruby:     return Color(hex: "FF2D55")
        }
    }

    var accentColor: Color {
        switch self {
        case .default_: return .blue
        case .ocean:    return Color(hex: "30D5C8")
        case .midnight: return Color(hex: "BF5AF2")
        case .sunset:   return Color(hex: "FFB347")
        case .roseGold: return Color(hex: "FFD1DC")
        case .emerald:  return Color(hex: "A8E6CF")
        case .slate:    return Color(hex: "C7C7CC")
        case .ruby:     return Color(hex: "FF6482")
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .default_: return [.blue, .blue.opacity(0.7)]
        case .ocean:    return [Color(hex: "0A84FF"), Color(hex: "30D5C8")]
        case .midnight: return [Color(hex: "5856D6"), Color(hex: "BF5AF2")]
        case .sunset:   return [Color(hex: "FF6B35"), Color(hex: "FFB347")]
        case .roseGold: return [Color(hex: "E8A0BF"), Color(hex: "FFD1DC")]
        case .emerald:  return [Color(hex: "30D158"), Color(hex: "A8E6CF")]
        case .slate:    return [Color(hex: "8E8E93"), Color(hex: "C7C7CC")]
        case .ruby:     return [Color(hex: "FF2D55"), Color(hex: "FF6482")]
        }
    }

    var iconName: String {
        switch self {
        case .default_: return "AppIcon"
        case .ocean:    return "AppIcon-Ocean"
        case .midnight: return "AppIcon-Midnight"
        case .sunset:   return "AppIcon-Sunset"
        case .roseGold: return "AppIcon-RoseGold"
        case .emerald:  return "AppIcon-Emerald"
        case .slate:    return "AppIcon-Slate"
        case .ruby:     return "AppIcon-Ruby"
        }
    }

    var previewGradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// The value to pass to `setAlternateIconName`. nil resets to default.
    var alternateIconValue: String? {
        self == .default_ ? nil : iconName
    }
}

// MARK: - ThemePickerView

struct ThemePickerView: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.default_.rawValue
    @Query private var settingsArray: [AppSettings]
    @State private var showingPaywall = false

    private var isPremium: Bool {
        settingsArray.first?.isPremium ?? false
    }

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .default_
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                themeSection
                iconSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.secondaryBackground)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    // MARK: - App Theme Section

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("App Theme")
                .font(.title3.weight(.bold))
                .padding(.leading, 4)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(AppTheme.allCases) { theme in
                    themeCard(for: theme)
                }
            }
        }
    }

    private func themeCard(for theme: AppTheme) -> some View {
        let isSelected = selectedTheme == theme
        let requiresPro = theme != .default_ && !isPremium

        return Button {
            if requiresPro {
                showingPaywall = true
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    selectedThemeRaw = theme.rawValue
                }
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
            }
        } label: {
            ZStack(alignment: .bottom) {
                // Gradient fill
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.previewGradient)
                    .frame(height: 120)

                // Bottom label area
                HStack {
                    Text(theme.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                    Spacer()

                    if requiresPro {
                        Text("PRO")
                            .font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)

                // Checkmark overlay
                if isSelected {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.white, lineWidth: 3)

                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                                    .padding(10)
                            }
                            Spacer()
                        }
                    }
                    .frame(height: 120)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: isSelected ? theme.primaryColor.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - App Icon Section

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("App Icon")
                .font(.title3.weight(.bold))
                .padding(.leading, 4)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(AppTheme.allCases) { theme in
                    iconCard(for: theme)
                }
            }
        }
    }

    private func iconCard(for theme: AppTheme) -> some View {
        let isCurrentIcon = selectedTheme == theme
        let requiresPro = theme != .default_ && !isPremium

        return Button {
            if requiresPro {
                showingPaywall = true
                return
            }
            setAppIcon(for: theme)
        } label: {
            HStack(spacing: 12) {
                // Icon preview circle
                ZStack {
                    Circle()
                        .fill(theme.previewGradient)
                        .frame(width: 50, height: 50)

                    Image(systemName: "app.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(theme.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if requiresPro {
                            Text("PRO")
                                .font(.system(size: 8, weight: .heavy))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.blue, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }

                    Text(theme.iconName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isCurrentIcon {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isCurrentIcon ? Color.blue.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Icon Setting

    private func setAppIcon(for theme: AppTheme) {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()

        UIApplication.shared.setAlternateIconName(theme.alternateIconValue) { error in
            if let error {
                print("Failed to set app icon: \(error.localizedDescription)")
            }
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            selectedThemeRaw = theme.rawValue
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ThemePickerView()
    }
    .modelContainer(for: AppSettings.self, inMemory: true)
}
