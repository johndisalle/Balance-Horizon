// LiveActivityView.swift — Balance Horizon
// Live Activity UI for lock screen and Dynamic Island.
//
// NOTE: In production, this file must be placed in the Widget Extension target
// (e.g., BalanceHorizonWidgets/) and included in that target's build settings.
// It is placed here in the main app Views folder for development reference.
// The BalanceAttributes type is defined in Services/LiveActivityManager.swift.

import SwiftUI
import WidgetKit
import ActivityKit

struct BalanceActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BalanceAttributes.self) { context in
            // MARK: - Lock Screen / Banner View (Expanded)
            lockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Label("Balance", systemImage: "dollarsign.circle.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.currentBalance.currencyFormatted)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(context.state.currentBalance >= 0 ? .green : .red)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.nextChangeDescription.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("Next: \(context.state.nextChangeDescription)")
                                .font(.caption.weight(.medium))
                                .lineLimit(1)

                            Spacer()

                            Text(formatAmount(context.state.nextChangeAmount))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(context.state.nextChangeAmount >= 0 ? .green : .red)

                            Text("on \(context.state.nextChangeDate.formatted(.dateTime.month(.abbreviated).day()))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                // MARK: - Compact Leading
                Image(systemName: "dollarsign.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            } compactTrailing: {
                // MARK: - Compact Trailing
                Text(context.state.currentBalance.compactCurrency)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(context.state.currentBalance >= 0 ? .green : .red)
            } minimal: {
                // MARK: - Minimal View
                Text(context.state.currentBalance.compactCurrency)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(context.state.currentBalance >= 0 ? .green : .red)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(state: BalanceAttributes.ContentState) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
                Text("Balance Horizon")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(state.currentBalance.currencyFormatted)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(state.currentBalance >= 0 ? .green : .red)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !state.nextChangeDescription.isEmpty {
                Divider()

                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Next:")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(state.nextChangeDescription)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)

                    Spacer()

                    Text(formatAmount(state.nextChangeAmount))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(state.nextChangeAmount >= 0 ? .green : .red)

                    Text("on \(state.nextChangeDate.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(.black.opacity(0.7))
        .activitySystemActionForegroundColor(.white)
    }

    // MARK: - Helpers

    private func formatAmount(_ amount: Double) -> String {
        let prefix = amount >= 0 ? "+" : ""
        return "\(prefix)\(abs(amount).currencyFormatted)"
    }
}
