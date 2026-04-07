// StreakBadgeView.swift — Balance Horizon
// Compact streak badge showing consecutive days of app usage.
// Displays a flame icon with streak count and animated effects at milestones.

import SwiftUI

// MARK: - StreakTracker

@Observable
class StreakTracker {
    private let defaults = UserDefaults.standard

    private let streakKey = "currentStreak"
    private let longestStreakKey = "longestStreak"
    private let lastActiveDateKey = "lastActiveDate"

    var currentStreak: Int {
        get { defaults.integer(forKey: streakKey) }
        set {
            defaults.set(newValue, forKey: streakKey)
            if newValue > longestStreak {
                longestStreak = newValue
            }
        }
    }

    var longestStreak: Int {
        get { defaults.integer(forKey: longestStreakKey) }
        set { defaults.set(newValue, forKey: longestStreakKey) }
    }

    var lastActiveDate: Date? {
        get { defaults.object(forKey: lastActiveDateKey) as? Date }
        set { defaults.set(newValue, forKey: lastActiveDateKey) }
    }

    func recordActivity() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        guard let last = lastActiveDate else {
            // First time ever
            currentStreak = 1
            lastActiveDate = today
            return
        }

        let lastDay = cal.startOfDay(for: last)

        if cal.isDate(lastDay, inSameDayAs: today) {
            // Already recorded today — do nothing
            return
        }

        if let yesterday = cal.date(byAdding: .day, value: -1, to: today),
           cal.isDate(lastDay, inSameDayAs: yesterday) {
            // Last active was yesterday — extend streak
            currentStreak += 1
            lastActiveDate = today
        } else {
            // Streak broken — reset
            currentStreak = 1
            lastActiveDate = today
        }
    }
}

// MARK: - StreakBadgeView

struct StreakBadgeView: View {
    let tracker: StreakTracker

    @State private var glowPhase: Bool = false

    private var streak: Int { tracker.currentStreak }

    private var flameGradient: LinearGradient {
        if streak >= 30 {
            return LinearGradient(
                colors: [.yellow, Color(red: 1.0, green: 0.84, blue: 0.0)],
                startPoint: .bottom,
                endPoint: .top
            )
        } else {
            return LinearGradient(
                colors: [.red, .orange],
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(flameGradient)
                .shadow(
                    color: glowColor.opacity(glowPhase ? 0.6 : 0.0),
                    radius: glowPhase ? 8 : 0
                )
                .overlay {
                    if streak >= 30 {
                        Image(systemName: "sparkle")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                            .offset(x: 6, y: -8)
                            .opacity(glowPhase ? 1.0 : 0.3)
                    }
                }

            Text("\(streak)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: streak)

            Text("day streak")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.cardBackground, in: Capsule())
        .overlay(Capsule().stroke(Color.gray.opacity(0.15), lineWidth: 1))
        .frame(width: 150)
        .onAppear {
            if streak >= 7 {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    glowPhase = true
                }
            }
        }
        .onChange(of: streak) {
            if streak >= 7 && !glowPhase {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    glowPhase = true
                }
            }
        }
    }

    private var glowColor: Color {
        streak >= 30 ? .yellow : .orange
    }
}
