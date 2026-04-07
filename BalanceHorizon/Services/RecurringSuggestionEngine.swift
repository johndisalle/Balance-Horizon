// RecurringSuggestionEngine.swift — Balance Horizon
// Auto-detects recurring patterns from the user's manual transaction entries
// and suggests converting them to recurring transactions.

import SwiftUI
import Observation

@Observable
class RecurringSuggestionEngine {

    struct RecurringSuggestion: Identifiable {
        let id: UUID = UUID()
        let category: String
        let description: String
        let amount: Double
        let suggestedFrequency: RecurringFrequency
        let confidence: Double
        let matchingDates: [Date]
    }

    // MARK: - Pattern Detection

    /// Analyzes non-recurring transactions and returns suggestions for those
    /// that appear to follow a recurring pattern.
    func detectPatterns(transactions: [Transaction]) -> [RecurringSuggestion] {
        // Only consider non-recurring, manual transactions
        let candidates = transactions.filter { !$0.isRecurring }

        // Group by (category, approximate amount within 10% tolerance)
        let groups = buildGroups(from: candidates)

        var suggestions: [RecurringSuggestion] = []

        for group in groups {
            // Need at least 3 transactions to detect a pattern
            guard group.transactions.count >= 3 else { continue }

            // Sort by date ascending
            let sorted = group.transactions.sorted { $0.date < $1.date }
            let dates = sorted.map { $0.date }

            // Calculate intervals in days between consecutive transactions
            let intervals = calculateIntervals(dates: dates)
            guard !intervals.isEmpty else { continue }

            // Try to match a frequency pattern
            if let (frequency, confidence) = matchFrequency(intervals: intervals), confidence > 0.6 {
                let averageAmount = sorted.map { $0.amount }.reduce(0, +) / Double(sorted.count)
                let roundedAmount = (averageAmount * 100).rounded() / 100

                let suggestion = RecurringSuggestion(
                    category: group.category,
                    description: group.description,
                    amount: roundedAmount,
                    suggestedFrequency: frequency,
                    confidence: confidence,
                    matchingDates: dates
                )
                suggestions.append(suggestion)
            }
        }

        // Sort by confidence descending
        return suggestions.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Grouping

    private struct TransactionGroup {
        let category: String
        let description: String
        let transactions: [Transaction]
    }

    /// Groups transactions by category and approximate amount (within 10% tolerance).
    private func buildGroups(from transactions: [Transaction]) -> [TransactionGroup] {
        // First, group by category
        var byCategory: [String: [Transaction]] = [:]
        for txn in transactions {
            byCategory[txn.category, default: []].append(txn)
        }

        var groups: [TransactionGroup] = []

        for (category, categoryTransactions) in byCategory {
            // Within each category, cluster by approximate amount (10% tolerance)
            var clusters: [[Transaction]] = []

            for txn in categoryTransactions {
                var placed = false
                for i in clusters.indices {
                    let referenceAmount = clusters[i][0].amount
                    let tolerance = referenceAmount * 0.10
                    if abs(txn.amount - referenceAmount) <= tolerance {
                        clusters[i].append(txn)
                        placed = true
                        break
                    }
                }
                if !placed {
                    clusters.append([txn])
                }
            }

            for cluster in clusters {
                // Use the most common description in the cluster, or the first one
                let desc = mostCommonDescription(in: cluster)
                groups.append(TransactionGroup(
                    category: category,
                    description: desc,
                    transactions: cluster
                ))
            }
        }

        return groups
    }

    private func mostCommonDescription(in transactions: [Transaction]) -> String {
        var counts: [String: Int] = [:]
        for txn in transactions {
            let key = txn.desc.trimmingCharacters(in: .whitespaces)
            if !key.isEmpty {
                counts[key, default: 0] += 1
            }
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? transactions.first?.desc ?? ""
    }

    // MARK: - Interval Analysis

    /// Returns the intervals in days between consecutive dates.
    private func calculateIntervals(dates: [Date]) -> [Double] {
        guard dates.count >= 2 else { return [] }
        var intervals: [Double] = []
        for i in 1..<dates.count {
            let days = dates[i].timeIntervalSince(dates[i - 1]) / 86400.0
            intervals.append(days)
        }
        return intervals
    }

    /// Tries to match the intervals to a known frequency pattern.
    /// Returns the frequency and a confidence score, or nil if no pattern matches.
    private func matchFrequency(intervals: [Double]) -> (RecurringFrequency, Double)? {
        let patterns: [(RecurringFrequency, Double, Double)] = [
            // (frequency, expected interval in days, tolerance)
            (.daily,    1.0,  0.5),
            (.weekly,   7.0,  2.0),
            (.biweekly, 14.0, 3.0),
            (.monthly,  30.0, 5.0),
        ]

        var bestMatch: (RecurringFrequency, Double)? = nil

        for (frequency, expected, tolerance) in patterns {
            let mean = intervals.reduce(0, +) / Double(intervals.count)

            // Check if the mean interval is within tolerance of expected
            guard abs(mean - expected) <= tolerance else { continue }

            // Count how many intervals fall within tolerance
            let matchingCount = intervals.filter { abs($0 - expected) <= tolerance }.count
            let matchRatio = Double(matchingCount) / Double(intervals.count)

            // Calculate standard deviation
            let variance = intervals.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(intervals.count)
            let stddev = variance.squareRoot()

            // Confidence: ratio of matching intervals * (1 - stddev/mean)
            // Clamp stddev/mean ratio so confidence doesn't go negative
            let normalizedStddev = mean > 0 ? min(stddev / mean, 1.0) : 1.0
            let confidence = matchRatio * (1.0 - normalizedStddev)

            if confidence > 0.6 {
                if bestMatch == nil || confidence > bestMatch!.1 {
                    bestMatch = (frequency, confidence)
                }
            }
        }

        return bestMatch
    }
}

// MARK: - Recurring Suggestion Banner

struct RecurringSuggestionBanner: View {
    let suggestions: [RecurringSuggestionEngine.RecurringSuggestion]
    var onAccept: (RecurringSuggestionEngine.RecurringSuggestion) -> Void
    var onDismiss: (RecurringSuggestionEngine.RecurringSuggestion) -> Void

    @State private var currentIndex: Int = 0

    var body: some View {
        if !suggestions.isEmpty, currentIndex < suggestions.count {
            let suggestion = suggestions[currentIndex]
            cardContent(for: suggestion)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(suggestion.id)
        }
    }

    @ViewBuilder
    private func cardContent(for suggestion: RecurringSuggestionEngine.RecurringSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Make this recurring?")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)

            HStack(spacing: 6) {
                Text(suggestion.description.isEmpty ? suggestion.category : suggestion.description)
                    .font(.subheadline.weight(.medium))
                Text(formattedAmount(suggestion.amount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
                Text("—")
                    .foregroundStyle(.secondary)
                Text("Every \(frequencyLabel(suggestion.suggestedFrequency))?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)

            HStack(spacing: 12) {
                Button {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    onAccept(suggestion)
                    advanceToNext()
                } label: {
                    Label("Yes, make recurring", systemImage: "checkmark")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green, in: Capsule())
                        .foregroundStyle(.white)
                }

                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onDismiss(suggestion)
                    advanceToNext()
                } label: {
                    Text("Not now")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.15), in: Capsule())
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
        .padding(.horizontal, 12)
    }

    private func advanceToNext() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentIndex += 1
        }
    }

    private func formattedAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    private func frequencyLabel(_ frequency: RecurringFrequency) -> String {
        switch frequency {
        case .daily:     return "day"
        case .weekly:    return "week"
        case .biweekly:  return "two weeks"
        case .monthly:   return "month"
        case .quarterly: return "quarter"
        case .yearly:    return "year"
        }
    }
}
