// RadialQuickAddMenu.swift — Balance Horizon
// A radial menu that explodes outward when long-pressing a calendar day.
// Six category buttons fan out in a circle with staggered spring animations,
// then tapping one opens a floating amount entry. Designed to feel magical.

import SwiftUI

struct RadialQuickAddMenu: View {
    @Binding var isPresented: Bool
    let selectedDate: Date
    let onAdd: (String, Double) -> Void

    // MARK: - Menu Items

    private struct MenuItem: Identifiable {
        let id = UUID()
        let category: String
        let icon: String
        let color: Color
    }

    private let items: [MenuItem] = [
        MenuItem(category: "Groceries",  icon: "cart",            color: .green),
        MenuItem(category: "Dining",     icon: "fork.knife",      color: .orange),
        MenuItem(category: "Transport",  icon: "car",             color: .blue),
        MenuItem(category: "Shopping",   icon: "bag",             color: .pink),
        MenuItem(category: "Bills",      icon: "doc.text",        color: .gray),
        MenuItem(category: "Coffee",     icon: "cup.and.saucer",  color: .brown),
    ]

    // MARK: - State

    @State private var buttonsExpanded = false
    @State private var selectedCategory: String? = nil
    @State private var showAmountEntry = false
    @State private var dismissing = false

    // MARK: - Layout

    private let radius: CGFloat = 70
    private let buttonSize: CGFloat = 44

    private func angle(for index: Int) -> Angle {
        let slice = 360.0 / Double(items.count)
        // Start from top (-90 degrees)
        return .degrees(-90 + slice * Double(index))
    }

    private func offset(for index: Int) -> CGSize {
        let a = angle(for: index).radians
        return CGSize(
            width: CGFloat(Foundation.cos(a)) * radius,
            height: CGFloat(Foundation.sin(a)) * radius
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.2)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            if showAmountEntry, let category = selectedCategory {
                // Amount entry card
                RadialAmountEntry(
                    category: category,
                    onConfirm: { amount in
                        onAdd(category, amount)
                        dismissWithSuccess()
                    },
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showAmountEntry = false
                            selectedCategory = nil
                        }
                        // Re-expand the radial buttons
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            buttonsExpanded = true
                        }
                    }
                )
                .transition(.scale(scale: 0.5).combined(with: .opacity))
            } else {
                // Radial buttons
                ZStack {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        radialButton(item: item, index: index)
                    }
                }
            }
        }
        .onAppear {
            expandButtons()
        }
    }

    // MARK: - Radial Button

    private func radialButton(item: MenuItem, index: Int) -> some View {
        let itemOffset = buttonsExpanded && !dismissing ? offset(for: index) : .zero
        let scale = buttonsExpanded && !dismissing ? 1.0 : 0.0

        return Button {
            selectCategory(item.category)
        } label: {
            ZStack {
                Circle()
                    .fill(item.color)
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(color: item.color.opacity(0.4), radius: 8, y: 4)

                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(item.category) expense")
        .offset(itemOffset)
        .scaleEffect(scale)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.65)
                .delay(Double(index) * 0.05),
            value: buttonsExpanded
        )
        .animation(
            .spring(response: 0.3, dampingFraction: 0.7)
                .delay(Double(items.count - 1 - index) * 0.03),
            value: dismissing
        )
    }

    // MARK: - Actions

    private func expandButtons() {
        withAnimation {
            buttonsExpanded = true
        }
    }

    private func selectCategory(_ category: String) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        selectedCategory = category

        // Collapse radial buttons
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            buttonsExpanded = false
        }

        // Show amount entry after buttons collapse
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75).delay(0.15)) {
            showAmountEntry = true
        }
    }

    private func dismiss() {
        dismissing = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            buttonsExpanded = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }

    private func dismissWithSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            showAmountEntry = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isPresented = false
        }
    }
}
