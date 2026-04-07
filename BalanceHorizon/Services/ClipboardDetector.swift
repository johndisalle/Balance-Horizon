// ClipboardDetector.swift — Balance Horizon
// Detects dollar amounts copied to the clipboard (from Venmo, receipts, texts, etc.)
// and offers a quick-add suggestion banner when the app opens.

import SwiftUI
import UIKit
import Observation

@Observable
class ClipboardDetector {
    var detectedAmount: Double? = nil
    var showingSuggestion: Bool = false

    private let lastAmountKey = "lastClipboardAmount"

    /// Reads the system clipboard and attempts to parse a dollar amount from its contents.
    /// Only triggers the suggestion banner when the amount differs from the last detected value.
    /// Uses hasStrings check first to avoid the iOS paste permission dialog on cold launch.
    func checkClipboard() {
        // hasStrings does NOT trigger the paste permission dialog
        guard UIPasteboard.general.hasStrings else { return }
        // Delay slightly so it doesn't fire during view transitions
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
            self.performClipboardCheck()
        }
    }

    private func performClipboardCheck() {
        guard let raw = UIPasteboard.general.string, !raw.isEmpty else { return }

        guard let amount = parseDollarAmount(from: raw) else { return }

        let lastAmount = UserDefaults.standard.double(forKey: lastAmountKey)
        // UserDefaults returns 0.0 for missing keys, so treat 0 as "no previous"
        if lastAmount != 0.0, abs(amount - lastAmount) < 0.001 {
            return
        }

        UserDefaults.standard.set(amount, forKey: lastAmountKey)
        detectedAmount = amount
        showingSuggestion = true
    }

    /// Resets all detection state.
    func clearDetection() {
        detectedAmount = nil
        showingSuggestion = false
    }

    // MARK: - Parsing

    /// Attempts to extract a dollar amount from a string.
    /// Matches patterns like "$47.50", "47.50", "$1,234.56", "1234.56",
    /// "paid 47.50", "total: $89.99".
    private func parseDollarAmount(from text: String) -> Double? {
        // Pattern breakdown:
        //   \$?\s*                  — optional dollar sign followed by optional whitespace
        //   ([0-9]{1,3}(?:,[0-9]{3})*)  — integer part with optional comma grouping (e.g. 1,234)
        //   (?:\.[0-9]{1,2})?      — optional decimal with 1-2 digits
        //
        // OR
        //   \$?\s*([0-9]+)         — plain integer (no commas)
        //   (?:\.[0-9]{1,2})?      — optional decimal
        let pattern = #"\$\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)|(?:^|[^0-9])([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{1,2})(?:[^0-9]|$)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: nsRange) else {
            return nil
        }

        // Try capture group 1 (dollar-sign prefixed) first, then group 2 (bare decimal)
        var captured: String?
        for groupIndex in 1...2 {
            let range = match.range(at: groupIndex)
            if range.location != NSNotFound, let swiftRange = Range(range, in: text) {
                captured = String(text[swiftRange])
                break
            }
        }

        guard let raw = captured else { return nil }

        // Strip commas for conversion
        let cleaned = raw.replacingOccurrences(of: ",", with: "")
        guard let value = Double(cleaned), value > 0, value < 1_000_000 else {
            return nil
        }

        return value
    }
}

// MARK: - Clipboard Suggestion Banner

struct ClipboardSuggestionBanner: View {
    @Bindable var detector: ClipboardDetector
    var onAdd: (Double) -> Void

    @State private var isVisible: Bool = false
    @State private var dismissTimer: Timer?

    var body: some View {
        if detector.showingSuggestion, let amount = detector.detectedAmount {
            bannerContent(amount: amount)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isVisible = true
                    }
                    triggerHaptic()
                    startAutoDismiss()
                }
                .onDisappear {
                    dismissTimer?.invalidate()
                }
        }
    }

    @ViewBuilder
    private func bannerContent(amount: Double) -> some View {
        HStack(spacing: 12) {
            Text("Add \(formatted(amount)) as an expense?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Button {
                triggerHaptic()
                onAdd(amount)
                dismiss()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, 12)
    }

    private func formatted(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    private func dismiss() {
        dismissTimer?.invalidate()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            detector.clearDetection()
            isVisible = false
        }
    }

    private func startAutoDismiss() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { _ in
            DispatchQueue.main.async {
                dismiss()
            }
        }
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
