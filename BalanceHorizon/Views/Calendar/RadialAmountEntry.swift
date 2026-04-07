// RadialAmountEntry.swift — Balance Horizon
// Floating amount entry card that appears after selecting a category
// from the radial quick-add menu. Shows category context, a large
// dollar input, quick-amount pills, and Add/Cancel actions.

import SwiftUI

struct RadialAmountEntry: View {
    let category: String
    let onConfirm: (Double) -> Void
    let onCancel: () -> Void

    @State private var amountText: String = ""
    @FocusState private var isFieldFocused: Bool
    @State private var appeared = false

    private var parsedAmount: Double? {
        Double(amountText)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Category header
            HStack(spacing: 8) {
                Image(systemName: CategoryIconsView.icon(for: category))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CategoryIconsView.color(for: category))
                Text(category)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.top, 4)

            // Amount input
            HStack(spacing: 4) {
                Text("$")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                TextField("0.00", text: $amountText)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .focused($isFieldFocused)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)

            // Quick amount pills
            HStack(spacing: 10) {
                ForEach(["5", "10", "20", "50"], id: \.self) { value in
                    Button {
                        amountText = value
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        Text("$\(value)")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(.systemGray5))
                            )
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Action buttons
            VStack(spacing: 10) {
                Button {
                    guard let amount = parsedAmount, amount > 0 else { return }
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    onConfirm(amount)
                } label: {
                    Text("Add")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(parsedAmount != nil && parsedAmount! > 0 ? .green : Color.gray.opacity(0.4))
                        )
                }
                .disabled(parsedAmount == nil || parsedAmount! <= 0)
                .buttonStyle(.plain)

                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        )
        .frame(width: 260)
        .scaleEffect(appeared ? 1 : 0.6)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFieldFocused = true
            }
        }
        .onSubmit {
            guard let amount = parsedAmount, amount > 0 else { return }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            onConfirm(amount)
        }
    }
}
