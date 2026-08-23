import SwiftUI

// MARK: - SketchMotifView
//
// Renders a journey motif as hand-drawn-feeling ink on paper. The pose
// evolves with `evolution` (0…1) across the journey — this is the progress
// visual: an abstract sketch that slowly changes shape, never a bar or badge.

struct SketchMotifView: View {

    let journey: DesireIntention
    /// 0…1 morph across the journey.
    var evolution: Double = 0.15
    var strokeColor: Color = Palette.wine
    var lineWidth: CGFloat = 2.1
    /// Ink presence: 0…1. Raise for hero moments, lower for background texture.
    var inkOpacity: Double = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Breathing phase for the living idle state.
    @State private var breathing = false

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height)
            let offsetX = (size.width - scale) / 2
            let offsetY = (size.height - scale) / 2
            let transform = CGAffineTransform(translationX: offsetX, y: offsetY)
                .scaledBy(x: scale, y: scale)

            let e = min(max(evolution, 0), 1)

            // Secondary marks first (under the main strokes).
            for (start, end, opacity) in SketchCurve.marks(journey: journey, evolution: e) {
                var path = Path()
                path.move(to: start.applying(transform))
                path.addLine(to: end.applying(transform))
                context.stroke(
                    path,
                    with: .color(strokeColor.opacity(opacity)),
                    style: StrokeStyle(lineWidth: lineWidth * 0.55, lineCap: .round)
                )
            }

            // Main strokes.
            for points in SketchCurve.strokes(journey: journey, evolution: e) {
                let path = sketchPath(points.map { $0.applying(transform) })
                context.stroke(
                    path,
                    with: .color(strokeColor.opacity(0.88 * inkOpacity)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityLabel(Text("a11y.sketch.hero"))
        .modifier(BreathingModifier(breathing: $breathing, reduceMotion: reduceMotion))
    }

    /// Converts a sampled polyline into a smooth curve through the points,
    /// preserving the wobble so it reads as pencil, not vector.
    private func sketchPath(_ pts: [CGPoint]) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        path.move(to: first)
        if pts.count < 3 {
            for p in pts.dropFirst() { path.addLine(to: p) }
            return path
        }
        var previous = first
        var previousTangent: CGPoint? = nil
        for i in 1..<pts.count {
            let current = pts[i]
            let next = pts[min(i + 1, pts.count - 1)]
            let mid = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: mid, control: previousTangent ?? previous)
            previousTangent = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
            previous = current
        }
        path.addLine(to: pts[pts.count - 1])
        return path
    }
}

/// Slow scale-breathing (~9s cycle). Disabled entirely under Reduce Motion.
private struct BreathingModifier: ViewModifier {
    @Binding var breathing: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(breathing ? 1.012 : 1.0)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 4.6).repeatForever(autoreverses: true)) {
                    breathing = true
                }
            }
    }
}

#Preview("Motifs") {
    VStack(spacing: Spacing.lg) {
        ForEach(DesireIntention.allCases) { journey in
            HStack(spacing: Spacing.md) {
                SketchMotifView(journey: journey, evolution: 0.05)
                    .frame(width: 110, height: 130)
                SketchMotifView(journey: journey, evolution: 0.5)
                    .frame(width: 110, height: 130)
                SketchMotifView(journey: journey, evolution: 0.95)
                    .frame(width: 110, height: 130)
            }
        }
    }
    .padding(Spacing.lg)
    .background(Palette.paper)
}
