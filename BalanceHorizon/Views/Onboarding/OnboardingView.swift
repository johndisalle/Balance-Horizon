// OnboardingView.swift — Balance Horizon
// 3-screen walkthrough shown on first launch. Collects starting balance
// and introduces the app's core concept: "See your balance tomorrow, today."

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var settingsArray: [AppSettings]
    @Environment(\.modelContext) private var context
    @State private var currentPage = 0
    @State private var startingBalance: String = ""

    private var settings: AppSettings {
        if let existing = settingsArray.first { return existing }
        let new = AppSettings()
        context.insert(new)
        return new
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                conceptPage.tag(1)
                balancePage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: currentPage)

            // Bottom button
            Button {
                if currentPage < 2 {
                    withAnimation { currentPage += 1 }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentPage == 2 ? "Get Started" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .disabled(currentPage == 2 && parsedBalance == nil)
        }
        .background(Color.secondaryBackground)
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 72))
                .foregroundStyle(.blue)
                .symbolEffect(.pulse)
            Text("Balance Horizon")
                .font(.largeTitle.weight(.bold))
            Text("Your financial future,\none day at a time.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private var conceptPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            Text("See Tomorrow's Balance Today")
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)
            Text("Add your income and expenses — recurring or one-time — and see your projected balance for every day ahead. No bank sync needed. 100% private.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }

    private var balancePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "banknote")
                .font(.system(size: 72))
                .foregroundStyle(.orange)
            Text("What's Your Balance?")
                .font(.title.weight(.bold))
            Text("Enter your current account balance to start projections.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack {
                Text("$")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                TextField("0.00", text: $startingBalance)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 48)

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private var parsedBalance: Double? {
        let cleaned = startingBalance.replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }

    private func completeOnboarding() {
        guard let balance = parsedBalance else { return }
        settings.startingBalance = balance
        settings.startingBalanceDate = Calendar.current.startOfDay(for: .now)
        settings.hasCompletedOnboarding = true

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
