// BudgetGoalsView.swift — Balance Horizon
// Compact ring bar for the calendar header and full budget goals management screen.

import SwiftUI
import SwiftData

// MARK: - Progress Ring Component

/// Reusable circular progress ring drawn with two stroked circles.
private struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat

    @State private var animatedProgress: Double = 0

    private var resolvedColor: Color {
        if progress > 1.0 { return .red }
        if progress > 0.8 { return .orange }
        return color
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(resolvedColor.opacity(0.2), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Foreground arc
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(resolvedColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: resolvedColor.opacity(0.4), radius: lineWidth * 0.6, x: 0, y: 0)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - BudgetGoalRingsBar

/// Compact horizontal strip of mini progress rings for the calendar header.
struct BudgetGoalRingsBar: View {
    @Query(filter: #Predicate<BudgetGoal> { $0.isActive }) private var goals: [BudgetGoal]
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Environment(\.modelContext) private var context

    @State private var selectedGoal: BudgetGoal?
    @State private var showGoalsView = false
    @State private var pulseOverBudget = false

    var body: some View {
        Group {
            if goals.isEmpty {
                emptyPrompt
            } else {
                ringsStrip
            }
        }
        .sheet(isPresented: $showGoalsView) {
            NavigationStack {
                BudgetGoalsView()
            }
        }
    }

    // MARK: Empty State

    private var emptyPrompt: some View {
        Button {
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
            showGoalsView = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Set budget goals")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.secondaryBackground, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Rings Strip

    private var ringsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(goals) { goal in
                    miniRing(for: goal)
                }
                addButton
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseOverBudget = true
            }
        }
    }

    private func miniRing(for goal: BudgetGoal) -> some View {
        let spent = spentThisMonth(for: goal.category)
        let prog = goal.progress(spent: spent)
        let goalColor = Color(hex: goal.color)
        let isOver = prog > 1.0
        let percent = Int(min(prog, 9.99) * 100)

        return VStack(spacing: 3) {
            ZStack {
                ProgressRing(progress: prog, color: goalColor, lineWidth: 6, size: 44)

                Image(systemName: goal.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isOver ? .red : goalColor)
            }
            .scaleEffect(isOver && pulseOverBudget ? 1.08 : 1.0)
            .popover(isPresented: popoverBinding(for: goal)) {
                popoverContent(goal: goal, spent: spent, percent: percent)
            }
            .onTapGesture {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                selectedGoal = goal
            }

            Text(goal.category)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 52)
    }

    private func popoverBinding(for goal: BudgetGoal) -> Binding<Bool> {
        Binding(
            get: { selectedGoal?.id == goal.id },
            set: { if !$0 { selectedGoal = nil } }
        )
    }

    private func popoverContent(goal: BudgetGoal, spent: Double, percent: Int) -> some View {
        VStack(spacing: 4) {
            Text(goal.category)
                .font(.caption.weight(.semibold))
            Text("\(spent.currencyFormatted) / \(goal.monthlyLimit.currencyFormatted) (\(percent)%)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .presentationCompactAdaptation(.popover)
    }

    private var addButton: some View {
        Button {
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
            showGoalsView = true
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.25), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Text("Add")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 52)
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private func spentThisMonth(for category: String) -> Double {
        let cal = Calendar.current
        let now = Date.now
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let start = cal.date(from: comps),
              let end = cal.date(byAdding: .month, value: 1, to: start) else { return 0 }

        return transactions
            .filter { $0.type == .expense && $0.category == category && $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - BudgetGoalsView

/// Full management screen for creating, viewing, and deleting budget goals.
struct BudgetGoalsView: View {
    @Query(sort: \BudgetGoal.createdAt) private var allGoals: [BudgetGoal]
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showCustomGoalSheet = false
    @State private var customCategory = ""
    @State private var customAmount = ""
    @State private var customIcon = "dollarsign.circle"
    @State private var customColor = "#007AFF"
    @State private var animateCards = false

    private var activeGoals: [BudgetGoal] {
        allGoals.filter { $0.isActive }
    }

    private var existingCategories: Set<String> {
        Set(allGoals.map { $0.category })
    }

    private let iconOptions = [
        "dollarsign.circle", "creditcard", "house", "heart",
        "book", "wrench.and.screwdriver", "pawprint", "airplane",
        "gift", "tshirt", "dumbbell", "cross.case"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                activeGoalsSection
                addGoalSection
                customGoalButton
            }
            .padding()
            .padding(.bottom, 20)
        }
        .background(Color.secondaryBackground)
        .navigationTitle("Budget Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !activeGoals.isEmpty {
                    Text("\(activeGoals.count) active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showCustomGoalSheet) {
            customGoalEditor
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                animateCards = true
            }
        }
    }

    // MARK: - Active Goals Section

    @ViewBuilder
    private var activeGoalsSection: some View {
        if !activeGoals.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Active Goals")
                    .font(.headline)
                    .padding(.leading, 4)

                ForEach(activeGoals) { goal in
                    goalCard(for: goal)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
            }
        }
    }

    private func goalCard(for goal: BudgetGoal) -> some View {
        let spent = spentThisMonth(for: goal.category)
        let prog = goal.progress(spent: spent)
        let goalColor = Color(hex: goal.color)
        let remaining = goal.monthlyLimit - spent
        let percent = Int(min(prog, 9.99) * 100)

        return HStack(spacing: 16) {
            // Large progress ring
            ZStack {
                ProgressRing(progress: prog, color: goalColor, lineWidth: 10, size: 80)

                Text("\(percent)%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(prog > 1.0 ? .red : .primary)
            }

            // Details
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: goal.icon)
                        .font(.subheadline)
                        .foregroundStyle(goalColor)
                    Text(goal.category)
                        .font(.subheadline.weight(.semibold))
                }

                Text("\(spent.currencyFormatted) spent of \(goal.monthlyLimit.currencyFormatted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Remaining / over
                if remaining >= 0 {
                    Text("\(remaining.currencyFormatted) left")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                } else {
                    Text("\(abs(remaining).currencyFormatted) over")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.red)
                }

                // Animated capsule progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(goalColor.opacity(0.15))
                            .frame(height: 6)

                        Capsule()
                            .fill(prog > 1.0 ? Color.red : (prog > 0.8 ? Color.orange : goalColor))
                            .frame(width: max(0, min(CGFloat(prog), 1.0) * geo.size.width), height: 6)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: prog)
                    }
                }
                .frame(height: 6)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteGoal(goal)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteGoal(goal)
            } label: {
                Label("Delete Goal", systemImage: "trash")
            }
        }
    }

    // MARK: - Add Goal Section

    private var addGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a Goal")
                .font(.headline)
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(BudgetGoal.suggestions, id: \.category) { suggestion in
                    let alreadyAdded = existingCategories.contains(suggestion.category)

                    Button {
                        guard !alreadyAdded else { return }
                        addSuggestion(suggestion)
                    } label: {
                        suggestionCard(suggestion: suggestion, alreadyAdded: alreadyAdded)
                    }
                    .buttonStyle(.plain)
                    .opacity(alreadyAdded ? 0.5 : 1.0)
                    .scaleEffect(animateCards ? 1.0 : 0.92)
                    .opacity(animateCards ? 1.0 : 0.0)
                }
            }
        }
    }

    private func suggestionCard(suggestion: BudgetGoal, alreadyAdded: Bool) -> some View {
        let goalColor = Color(hex: suggestion.color)

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(goalColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                if alreadyAdded {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(goalColor)
                } else {
                    Image(systemName: suggestion.icon)
                        .font(.body)
                        .foregroundStyle(goalColor)
                }
            }

            Text(suggestion.category)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Text(suggestion.monthlyLimit.currencyFormatted)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
    }

    // MARK: - Custom Goal

    private var customGoalButton: some View {
        Button {
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
            showCustomGoalSheet = true
        } label: {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.subheadline)
                Text("Create Custom Goal")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var customGoalEditor: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    TextField("Category name", text: $customCategory)
                        .textInputAutocapitalization(.words)
                }

                Section("Monthly Limit") {
                    TextField("Amount", text: $customAmount)
                        .keyboardType(.decimalPad)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                customIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(customIcon == icon ? .blue : .secondary)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        customIcon == icon ? Color.blue.opacity(0.12) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button {
                                customColor = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if customColor == hex {
                                            Circle()
                                                .strokeBorder(.white, lineWidth: 2.5)
                                                .frame(width: 28, height: 28)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Custom Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCustomGoalSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveCustomGoal()
                    }
                    .fontWeight(.semibold)
                    .disabled(customCategory.trimmingCharacters(in: .whitespaces).isEmpty || Double(customAmount) == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var colorOptions: [String] {
        ["#FF6B35", "#30D158", "#AF52DE", "#FF2D55", "#007AFF", "#FF9500",
         "#5856D6", "#00C7BE", "#FF3B30", "#34C759", "#FFD60A", "#BF5AF2"]
    }

    // MARK: - Actions

    private func addSuggestion(_ suggestion: BudgetGoal) {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()

        let goal = BudgetGoal(
            category: suggestion.category,
            monthlyLimit: suggestion.monthlyLimit,
            icon: suggestion.icon,
            color: suggestion.color
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            context.insert(goal)
        }
    }

    private func deleteGoal(_ goal: BudgetGoal) {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            context.delete(goal)
        }
    }

    private func saveCustomGoal() {
        guard let amount = Double(customAmount),
              !customCategory.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()

        let goal = BudgetGoal(
            category: customCategory.trimmingCharacters(in: .whitespaces),
            monthlyLimit: amount,
            icon: customIcon,
            color: customColor
        )
        context.insert(goal)
        showCustomGoalSheet = false

        customCategory = ""
        customAmount = ""
        customIcon = "dollarsign.circle"
        customColor = "#007AFF"
    }

    // MARK: - Helpers

    private func spentThisMonth(for category: String) -> Double {
        let cal = Calendar.current
        let now = Date.now
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let start = cal.date(from: comps),
              let end = cal.date(byAdding: .month, value: 1, to: start) else { return 0 }

        return transactions
            .filter { $0.type == .expense && $0.category == category && $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.amount }
    }
}
