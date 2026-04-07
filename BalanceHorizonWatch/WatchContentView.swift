import SwiftUI

struct WatchContentView: View {
    @State private var todayBalance: Double = 0.0
    @State private var forecast: [(day: String, balance: Double)] = []
    @State private var showAddTransaction = false

    private let sharedDefaults = UserDefaults(suiteName: "group.com.ellasid.balancehorizon")

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // MARK: - Today's Balance
                Text(formatCurrency(todayBalance))
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundColor(balanceColor(todayBalance))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("Today's Balance")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)

                Divider()
                    .padding(.vertical, 4)

                // MARK: - 3-Day Mini Forecast
                ForEach(forecast, id: \.day) { entry in
                    HStack {
                        Text(entry.day)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCurrency(entry.balance))
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundColor(balanceColor(entry.balance))
                    }
                    .padding(.horizontal, 4)
                }

                Divider()
                    .padding(.vertical, 4)

                // MARK: - Quick Add Button
                Button {
                    showAddTransaction = true
                } label: {
                    Label("Add Transaction", systemImage: "plus.circle.fill")
                        .font(.system(.footnote, design: .rounded).bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Balance")
        .sheet(isPresented: $showAddTransaction) {
            AddWatchTransactionView()
        }
        .onAppear {
            loadData()
        }
    }

    // MARK: - Helpers

    private func loadData() {
        todayBalance = sharedDefaults?.double(forKey: "todayBalance") ?? 0.0

        let calendar = Calendar.current
        let today = Date()
        var forecastEntries: [(String, Double)] = []

        for offset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let key = "forecastBalance_\(offset)"
            let balance = sharedDefaults?.double(forKey: key) ?? todayBalance

            let dayName: String
            if offset == 0 {
                dayName = "Today"
            } else if offset == 1 {
                dayName = "Tomorrow"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                dayName = formatter.string(from: date)
            }

            forecastEntries.append((dayName, balance))
        }

        forecast = forecastEntries
    }

    private func balanceColor(_ value: Double) -> Color {
        if value >= 100 {
            return .green
        } else if value >= 0 {
            return .orange
        } else {
            return .red
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

#Preview {
    WatchContentView()
}
