// BalanceChartView.swift — Balance Horizon
// Custom-drawn balance line chart using SwiftUI Path for full control
// over appearance. Renders a smooth curved line with gradient fill,
// proper Y-axis scaling, and labeled axes.

import SwiftUI

struct BalanceChartView: View {
    let data: [(Date, Double)]
    var height: CGFloat = 140

    private var balances: [Double] { data.map(\.1) }
    private var minBalance: Double {
        let m = balances.min() ?? 0
        let range = (balances.max() ?? 1) - m
        return m - range * 0.1
    }
    private var maxBalance: Double {
        let m = balances.max() ?? 1
        let range = m - (balances.min() ?? 0)
        return m + range * 0.1
    }
    private var balanceRange: Double {
        let r = maxBalance - minBalance
        return r > 0 ? r : 1
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 4) {
                // Y-axis labels
                yAxisLabels
                    .frame(width: 44)

                // Chart area
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    ZStack(alignment: .topLeading) {
                        // Grid lines
                        gridLines(width: w, height: h)

                        // Gradient fill under the line
                        gradientFill(width: w, height: h)

                        // Main line
                        chartLine(width: w, height: h)

                        // Point dots at significant changes
                        pointDots(width: w, height: h)
                    }
                }
                .frame(height: height)
            }

            // X-axis labels
            xAxisLabels
                .padding(.leading, 48)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Y-Axis

    private var yAxisLabels: some View {
        VStack(alignment: .trailing) {
            Text(maxBalance.compactCurrency)
            Spacer()
            Text(((maxBalance + minBalance) / 2).compactCurrency)
            Spacer()
            Text(minBalance.compactCurrency)
        }
        .font(.system(size: 10, design: .rounded))
        .foregroundStyle(.secondary)
        .frame(height: height)
    }

    // MARK: - X-Axis

    private var xAxisLabels: some View {
        HStack {
            if let first = data.first {
                Text(first.0, format: .dateTime.day())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if data.count > 7 {
                let mid = data[data.count / 2]
                Text(mid.0, format: .dateTime.day())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let last = data.last {
                Text(last.0, format: .dateTime.day())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Grid Lines

    private func gridLines(width: CGFloat, height: CGFloat) -> some View {
        Canvas { ctx, size in
            let lineCount = 3
            for i in 0...lineCount {
                let y = CGFloat(i) / CGFloat(lineCount) * height
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: width, y: y))
                }
                ctx.stroke(path, with: .color(.gray.opacity(0.15)), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
            }
        }
    }

    // MARK: - Chart Line

    private func chartLine(width: CGFloat, height: CGFloat) -> some View {
        let points = dataPoints(width: width, height: height)
        return SmoothLine(points: points)
            .stroke(
                LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
    }

    // MARK: - Gradient Fill

    private func gradientFill(width: CGFloat, height: CGFloat) -> some View {
        let points = dataPoints(width: width, height: height)
        return SmoothLineFill(points: points, bottomY: height)
            .fill(
                LinearGradient(
                    colors: [.blue.opacity(0.2), .blue.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    // MARK: - Point Dots

    private func pointDots(width: CGFloat, height: CGFloat) -> some View {
        let points = dataPoints(width: width, height: height)
        // Show dots at first, last, min, and max points
        let indices = significantIndices()

        return ForEach(indices, id: \.self) { i in
            if i < points.count {
                Circle()
                    .fill(.blue)
                    .frame(width: 6, height: 6)
                    .shadow(color: .blue.opacity(0.4), radius: 3)
                    .position(points[i])
            }
        }
    }

    // MARK: - Helpers

    private func dataPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard data.count >= 2 else { return [] }
        return data.enumerated().map { i, item in
            let x = CGFloat(i) / CGFloat(data.count - 1) * width
            let y = (1 - CGFloat((item.1 - minBalance) / balanceRange)) * height
            return CGPoint(x: x, y: y)
        }
    }

    private func significantIndices() -> [Int] {
        guard !balances.isEmpty else { return [] }
        var indices = Set<Int>()
        indices.insert(0)
        indices.insert(balances.count - 1)
        if let minIdx = balances.enumerated().min(by: { $0.element < $1.element })?.offset {
            indices.insert(minIdx)
        }
        if let maxIdx = balances.enumerated().max(by: { $0.element < $1.element })?.offset {
            indices.insert(maxIdx)
        }
        return Array(indices).sorted()
    }
}

// MARK: - Smooth Line Shape (Quadratic Bezier)

private struct SmoothLine: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        guard points.count >= 2 else { return Path() }
        var path = Path()
        path.move(to: points[0])

        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let midX = (prev.x + curr.x) / 2
            path.addCurve(
                to: curr,
                control1: CGPoint(x: midX, y: prev.y),
                control2: CGPoint(x: midX, y: curr.y)
            )
        }
        return path
    }
}

// MARK: - Smooth Line Fill Shape

private struct SmoothLineFill: Shape {
    let points: [CGPoint]
    let bottomY: CGFloat

    func path(in rect: CGRect) -> Path {
        guard points.count >= 2 else { return Path() }
        var path = Path()
        path.move(to: CGPoint(x: points[0].x, y: bottomY))
        path.addLine(to: points[0])

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let midX = (prev.x + curr.x) / 2
            path.addCurve(
                to: curr,
                control1: CGPoint(x: midX, y: prev.y),
                control2: CGPoint(x: midX, y: curr.y)
            )
        }

        path.addLine(to: CGPoint(x: points.last!.x, y: bottomY))
        path.closeSubpath()
        return path
    }
}
