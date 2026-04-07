// CelebrationView.swift — Balance Horizon
// Full confetti and celebration system: physics-based particle animation,
// milestone tracking with persistent state, and overlay presentation.

import SwiftUI

// MARK: - Confetti Particle

/// A single confetti particle with physics state.
private struct ConfettiParticle: Identifiable {
    let id = UUID()
    // Position
    var x: CGFloat
    var y: CGFloat
    // Velocity
    var vx: CGFloat
    var vy: CGFloat
    // Appearance
    let color: Color
    let shape: ParticleShape
    let size: CGFloat
    var rotation: Double
    let rotationSpeed: Double
    // Wobble
    let wobbleAmplitude: CGFloat
    let wobbleFrequency: CGFloat
    let wobblePhase: CGFloat
    // Lifetime
    let fadeDuration: CGFloat
    var opacity: CGFloat = 1.0

    enum ParticleShape: CaseIterable {
        case circle, square, ribbon
    }
}

// MARK: - ConfettiView

/// A full-screen confetti explosion rendered via TimelineView + Canvas for
/// buttery-smooth 60 fps animation. Particles obey gravity, spin, wobble,
/// and gracefully fade out.
struct ConfettiView: View {
    var colors: [Color] = [
        .yellow, .blue, .green, .pink, .purple, .orange,
        Color(red: 1, green: 0.84, blue: 0),   // gold
        Color(red: 0.3, green: 0.85, blue: 1),  // sky
        Color(red: 1, green: 0.4, blue: 0.6),   // hot pink
    ]

    var onFinished: (() -> Void)?

    @State private var particles: [ConfettiParticle] = []
    @State private var startDate: Date?
    @State private var finished = false

    private let particleCount = 90
    private let gravity: CGFloat = 600
    private let duration: CGFloat = 3.2

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard let start = startDate else { return }
                let elapsed = CGFloat(timeline.date.timeIntervalSince(start))
                if elapsed > duration && !finished {
                    DispatchQueue.main.async {
                        finished = true
                        onFinished?()
                    }
                }
                for i in particles.indices {
                    drawParticle(
                        context: context,
                        particle: particles[i],
                        elapsed: elapsed,
                        canvasSize: size
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            spawnParticles()
            startDate = .now
        }
    }

    // MARK: Spawn

    private func spawnParticles() {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                x: 0,
                y: 0,
                vx: CGFloat.random(in: -220...220),
                vy: CGFloat.random(in: -850 ... -400),
                color: colors.randomElement()!,
                shape: ConfettiParticle.ParticleShape.allCases.randomElement()!,
                size: CGFloat.random(in: 4...10),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -540...540),
                wobbleAmplitude: CGFloat.random(in: 20...60),
                wobbleFrequency: CGFloat.random(in: 2...5),
                wobblePhase: CGFloat.random(in: 0 ... .pi * 2),
                fadeDuration: CGFloat.random(in: 2.0...3.0)
            )
        }
    }

    // MARK: Draw

    private func drawParticle(
        context: GraphicsContext,
        particle: ConfettiParticle,
        elapsed: CGFloat,
        canvasSize: CGSize
    ) {
        let t = elapsed

        // Physics integration
        let baseX = canvasSize.width / 2 + particle.vx * t
        let wobble = particle.wobbleAmplitude * sin(particle.wobbleFrequency * t + particle.wobblePhase)
        let px = baseX + wobble
        let py = canvasSize.height * 0.15
            + particle.vy * t
            + 0.5 * gravity * t * t

        // Off-screen early exit
        guard py < canvasSize.height + 40 else { return }

        // Opacity fade
        let fadeStart = particle.fadeDuration * 0.55
        let alpha: CGFloat
        if t < fadeStart {
            alpha = 1.0
        } else {
            alpha = max(0, 1.0 - (t - fadeStart) / (particle.fadeDuration - fadeStart))
        }
        guard alpha > 0.01 else { return }

        // Rotation
        let angle = Angle.degrees(particle.rotation + particle.rotationSpeed * Double(t))

        var ctx = context
        ctx.opacity = Double(alpha)
        ctx.translateBy(x: px, y: py)
        ctx.rotate(by: angle)

        let s = particle.size
        let rect: CGRect
        let path: Path

        switch particle.shape {
        case .circle:
            rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
            path = Path(ellipseIn: rect)
        case .square:
            rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
            path = Path(rect)
        case .ribbon:
            let w = s * 0.35
            let h = s * 1.8
            rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
            path = Path(rect)
        }

        ctx.fill(path, with: .color(particle.color))

        // Tiny highlight on circles and squares for depth
        if particle.shape != .ribbon {
            let highlightRect = CGRect(
                x: rect.minX + rect.width * 0.15,
                y: rect.minY + rect.height * 0.12,
                width: rect.width * 0.35,
                height: rect.height * 0.3
            )
            var highlightCtx = ctx
            highlightCtx.opacity = 0.35
            highlightCtx.fill(
                Path(ellipseIn: highlightRect),
                with: .color(.white)
            )
        }
    }
}

// MARK: - Milestone

/// A celebration milestone that can be triggered once.
struct Milestone: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let confettiColors: [Color]

    static func == (lhs: Milestone, rhs: Milestone) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - MilestoneTracker

/// Checks user progress against a catalogue of milestones and returns the
/// first unshown one, persisting shown state across launches.
@Observable
final class MilestoneTracker {
    // Persisted as comma-separated milestone IDs
    @ObservationIgnored
    private var _shownRaw: String {
        get { UserDefaults.standard.string(forKey: "shownMilestones") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "shownMilestones") }
    }

    private var shownIDs: Set<String> {
        Set(_shownRaw.split(separator: ",").map(String.init))
    }

    /// Call after any state change that might unlock a milestone.
    /// Returns the first unshown milestone, if any.
    func checkMilestones(
        transactionCount: Int,
        daysSinceStart: Int,
        currentBalance: Double,
        startingBalance: Double,
        savingsRate: Double
    ) -> Milestone? {
        let all = Self.catalogue(
            transactionCount: transactionCount,
            daysSinceStart: daysSinceStart,
            currentBalance: currentBalance,
            startingBalance: startingBalance,
            savingsRate: savingsRate
        )
        let shown = shownIDs
        return all.first { !shown.contains($0.id) }
    }

    /// Record a milestone so it won't fire again.
    func markShown(_ milestone: Milestone) {
        var ids = shownIDs
        ids.insert(milestone.id)
        _shownRaw = ids.sorted().joined(separator: ",")
    }

    /// Reset all milestones (useful for testing / settings).
    func resetAll() {
        _shownRaw = ""
    }

    // MARK: Catalogue

    /// Returns milestones whose conditions are met, in priority order.
    private static func catalogue(
        transactionCount: Int,
        daysSinceStart: Int,
        currentBalance: Double,
        startingBalance: Double,
        savingsRate: Double
    ) -> [Milestone] {
        var result: [Milestone] = []

        if transactionCount >= 1 {
            result.append(Milestone(
                id: "first_transaction",
                icon: "star.fill",
                title: "First Step!",
                subtitle: "You've logged your first transaction",
                confettiColors: [.yellow, .orange, .pink]
            ))
        }

        if daysSinceStart >= 7 {
            result.append(Milestone(
                id: "7_day_streak",
                icon: "flame.fill",
                title: "One Week!",
                subtitle: "You've been tracking for a full week",
                confettiColors: [.orange, .red, .yellow]
            ))
        }

        if daysSinceStart >= 30 {
            result.append(Milestone(
                id: "30_day_streak",
                icon: "crown.fill",
                title: "Monthly Master!",
                subtitle: "A full month of financial awareness",
                confettiColors: [.purple, .blue, .pink]
            ))
        }

        if transactionCount >= 50 {
            result.append(Milestone(
                id: "50_transactions",
                icon: "bolt.fill",
                title: "Power Tracker!",
                subtitle: "50 transactions logged",
                confettiColors: [.blue, .cyan, .green]
            ))
        }

        if transactionCount >= 100 {
            result.append(Milestone(
                id: "100_transactions",
                icon: "trophy.fill",
                title: "Century Club!",
                subtitle: "100 transactions tracked",
                confettiColors: [Color(red: 1, green: 0.84, blue: 0), .orange, .yellow]
            ))
        }

        if startingBalance > 0, currentBalance > startingBalance * 1.1 {
            result.append(Milestone(
                id: "balance_up_10",
                icon: "chart.line.uptrend.xyaxis",
                title: "Growing!",
                subtitle: "Your balance is up 10%+ from when you started",
                confettiColors: [.green, .mint, .teal]
            ))
        }

        if savingsRate > 0.20 {
            result.append(Milestone(
                id: "savings_rate_20",
                icon: "banknote.fill",
                title: "Super Saver!",
                subtitle: "You're saving over 20% of your income",
                confettiColors: [.green, .yellow, .mint]
            ))
        }

        return result
    }
}

// MARK: - CelebrationOverlay

/// Full-screen overlay combining confetti, a celebration card, and haptics.
struct CelebrationOverlay: View {
    let milestone: Milestone
    var onDismiss: () -> Void

    @State private var cardScale: CGFloat = 0.3
    @State private var cardOpacity: CGFloat = 0
    @State private var dimOpacity: CGFloat = 0
    @State private var showConfetti = true
    @State private var iconBounce: CGFloat = 0

    var body: some View {
        ZStack {
            // Dim background
            Color.black
                .opacity(dimOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Confetti layer
            if showConfetti {
                ConfettiView(colors: milestone.confettiColors) {
                    showConfetti = false
                }
            }

            // Card
            celebrationCard
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65, blendDuration: 0)) {
                cardScale = 1.0
                cardOpacity = 1.0
                dimOpacity = 0.3
            }
            // Icon bounce after card lands
            withAnimation(.spring(response: 0.35, dampingFraction: 0.4, blendDuration: 0).delay(0.35)) {
                iconBounce = 1.0
            }
            triggerHaptics()
        }
    }

    // MARK: Card

    private var celebrationCard: some View {
        VStack(spacing: 16) {
            Image(systemName: milestone.icon)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: milestone.confettiColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(iconBounce)
                .padding(.top, 24)

            Text(milestone.title)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            Text(milestone.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Button {
                dismiss()
            } label: {
                Text("Nice!")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: milestone.confettiColors.isEmpty
                                ? [.blue, .purple]
                                : Array(milestone.confettiColors.prefix(2)),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 30, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: Helpers

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            cardScale = 0.8
            cardOpacity = 0
            dimOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }

    /// Triple haptic burst: success, then two light impacts.
    private func triggerHaptics() {
        let success = UINotificationFeedbackGenerator()
        success.notificationOccurred(.success)

        let impact = UIImpactFeedbackGenerator(style: .light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            impact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            impact.impactOccurred()
        }
    }
}

// MARK: - View Extension

/// Convenience modifier to attach a celebration overlay to any view.
struct CelebrationModifier: ViewModifier {
    let milestone: Milestone?
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content.overlay {
            if let milestone {
                CelebrationOverlay(milestone: milestone, onDismiss: onDismiss)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: milestone?.id)
    }
}

extension View {
    /// Show a full-screen confetti celebration when a milestone is present.
    /// Set the binding to `nil` in `onDismiss` to hide.
    func celebrationOverlay(
        milestone: Milestone?,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(CelebrationModifier(milestone: milestone, onDismiss: onDismiss))
    }
}
