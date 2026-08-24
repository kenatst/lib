import SwiftUI

// MARK: - Reusable editorial sketch language
//
// Seven poetic scenes assembled from the same wine-ink vocabulary. The
// drawings remain suggestive and human without depicting explicit anatomy.

enum EditorialSketchScene: Sendable {
    case profiles
    case almostTouching
    case handOnHeart
    case threshold
    case bloom
    case moonThread
    case ribbon
}

struct EditorialSketchView: View {
    let scene: EditorialSketchScene
    var color: Color = Palette.wine
    var wash: Color = Palette.blush
    var lineWidth: CGFloat = 1.8
    var showsWash = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        ZStack {
            if showsWash {
                InkWashShape()
                    .fill(wash.opacity(0.45))
                    .padding(8)
            }

            Canvas { context, size in
                let paths = paths(in: size)
                for (index, path) in paths.enumerated() {
                    let opacity = index == paths.count - 1 ? 0.58 : 0.92
                    context.stroke(
                        path,
                        with: .color(color.opacity(opacity)),
                        style: StrokeStyle(
                            lineWidth: index == paths.count - 1 ? lineWidth * 0.7 : lineWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }
            .padding(18)
            .mask(alignment: .leading) {
                GeometryReader { proxy in
                    Rectangle()
                        .frame(width: proxy.size.width * (revealed ? 1 : 0.03))
                }
            }
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !revealed else { return }
            withAnimation(Motion.resolved(Motion.ink, reduceMotion: reduceMotion)) {
                revealed = true
            }
        }
    }

    private func paths(in size: CGSize) -> [Path] {
        switch scene {
        case .profiles: profiles(in: size)
        case .almostTouching: almostTouching(in: size)
        case .handOnHeart: handOnHeart(in: size)
        case .threshold: threshold(in: size)
        case .bloom: bloom(in: size)
        case .moonThread: moonThread(in: size)
        case .ribbon: ribbon(in: size)
        }
    }

    private func point(_ x: CGFloat, _ y: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * x, y: size.height * y)
    }

    private func profiles(in size: CGSize) -> [Path] {
        var left = Path()
        left.move(to: point(0.08, 0.84, in: size))
        left.addCurve(to: point(0.31, 0.34, in: size), control1: point(0.15, 0.69, in: size), control2: point(0.18, 0.42, in: size))
        left.addCurve(to: point(0.43, 0.48, in: size), control1: point(0.38, 0.3, in: size), control2: point(0.38, 0.41, in: size))
        left.addCurve(to: point(0.38, 0.73, in: size), control1: point(0.48, 0.58, in: size), control2: point(0.41, 0.64, in: size))

        var right = Path()
        right.move(to: point(0.92, 0.82, in: size))
        right.addCurve(to: point(0.69, 0.31, in: size), control1: point(0.85, 0.66, in: size), control2: point(0.82, 0.4, in: size))
        right.addCurve(to: point(0.57, 0.48, in: size), control1: point(0.62, 0.3, in: size), control2: point(0.62, 0.4, in: size))
        right.addCurve(to: point(0.62, 0.74, in: size), control1: point(0.52, 0.57, in: size), control2: point(0.59, 0.65, in: size))

        var thread = Path()
        thread.move(to: point(0.5, 0.08, in: size))
        thread.addCurve(to: point(0.5, 0.91, in: size), control1: point(0.42, 0.31, in: size), control2: point(0.59, 0.67, in: size))
        return [left, right, thread]
    }

    private func almostTouching(in size: CGSize) -> [Path] {
        var upper = Path()
        upper.move(to: point(0.03, 0.28, in: size))
        upper.addCurve(to: point(0.45, 0.49, in: size), control1: point(0.18, 0.29, in: size), control2: point(0.3, 0.43, in: size))
        upper.addCurve(to: point(0.49, 0.55, in: size), control1: point(0.47, 0.5, in: size), control2: point(0.48, 0.53, in: size))

        var lower = Path()
        lower.move(to: point(0.97, 0.76, in: size))
        lower.addCurve(to: point(0.55, 0.57, in: size), control1: point(0.81, 0.74, in: size), control2: point(0.69, 0.61, in: size))
        lower.addCurve(to: point(0.51, 0.55, in: size), control1: point(0.53, 0.57, in: size), control2: point(0.52, 0.55, in: size))

        var echo = Path()
        echo.move(to: point(0.16, 0.38, in: size))
        echo.addCurve(to: point(0.42, 0.52, in: size), control1: point(0.27, 0.4, in: size), control2: point(0.34, 0.48, in: size))
        return [upper, lower, echo]
    }

    private func handOnHeart(in size: CGSize) -> [Path] {
        var shoulder = Path()
        shoulder.move(to: point(0.11, 0.88, in: size))
        shoulder.addCurve(to: point(0.48, 0.18, in: size), control1: point(0.15, 0.52, in: size), control2: point(0.28, 0.2, in: size))
        shoulder.addCurve(to: point(0.82, 0.72, in: size), control1: point(0.69, 0.2, in: size), control2: point(0.73, 0.51, in: size))

        var hand = Path()
        hand.move(to: point(0.18, 0.72, in: size))
        hand.addCurve(to: point(0.47, 0.58, in: size), control1: point(0.28, 0.67, in: size), control2: point(0.38, 0.61, in: size))
        hand.addCurve(to: point(0.69, 0.69, in: size), control1: point(0.56, 0.55, in: size), control2: point(0.64, 0.62, in: size))

        var pulse = Path()
        pulse.move(to: point(0.48, 0.49, in: size))
        pulse.addCurve(to: point(0.58, 0.44, in: size), control1: point(0.51, 0.43, in: size), control2: point(0.55, 0.42, in: size))
        pulse.addCurve(to: point(0.64, 0.54, in: size), control1: point(0.62, 0.46, in: size), control2: point(0.64, 0.5, in: size))
        return [shoulder, hand, pulse]
    }

    private func threshold(in size: CGSize) -> [Path] {
        var curtain = Path()
        curtain.move(to: point(0.24, 0.08, in: size))
        curtain.addCurve(to: point(0.3, 0.91, in: size), control1: point(0.14, 0.35, in: size), control2: point(0.37, 0.66, in: size))
        curtain.move(to: point(0.75, 0.08, in: size))
        curtain.addCurve(to: point(0.69, 0.91, in: size), control1: point(0.84, 0.35, in: size), control2: point(0.63, 0.66, in: size))

        var light = Path()
        light.move(to: point(0.49, 0.13, in: size))
        light.addLine(to: point(0.5, 0.88, in: size))
        light.addLine(to: point(0.85, 0.98, in: size))
        light.move(to: point(0.5, 0.88, in: size))
        light.addLine(to: point(0.15, 0.98, in: size))
        return [curtain, light]
    }

    private func bloom(in size: CGSize) -> [Path] {
        var petals = Path()
        let center = point(0.5, 0.55, in: size)
        for index in 0..<6 {
            let angle = CGFloat(index) * .pi / 3 - .pi / 2
            let side = angle + 0.7
            let end = CGPoint(x: center.x + cos(angle) * size.width * 0.32, y: center.y + sin(angle) * size.height * 0.34)
            petals.move(to: center)
            petals.addCurve(
                to: end,
                control1: CGPoint(x: center.x + cos(side) * size.width * 0.17, y: center.y + sin(side) * size.height * 0.16),
                control2: CGPoint(x: end.x - cos(side) * size.width * 0.12, y: end.y - sin(side) * size.height * 0.1)
            )
            petals.addCurve(
                to: center,
                control1: CGPoint(x: end.x + cos(side) * size.width * 0.09, y: end.y + sin(side) * size.height * 0.08),
                control2: CGPoint(x: center.x - cos(side) * size.width * 0.12, y: center.y - sin(side) * size.height * 0.1)
            )
        }
        var stem = Path()
        stem.move(to: center)
        stem.addCurve(to: point(0.44, 0.98, in: size), control1: point(0.54, 0.72, in: size), control2: point(0.43, 0.85, in: size))
        return [petals, stem]
    }

    private func moonThread(in size: CGSize) -> [Path] {
        var moon = Path()
        moon.move(to: point(0.65, 0.16, in: size))
        moon.addCurve(to: point(0.63, 0.7, in: size), control1: point(0.38, 0.25, in: size), control2: point(0.39, 0.61, in: size))
        moon.addCurve(to: point(0.65, 0.16, in: size), control1: point(0.48, 0.58, in: size), control2: point(0.5, 0.3, in: size))

        var thread = Path()
        thread.move(to: point(0.08, 0.82, in: size))
        thread.addCurve(to: point(0.9, 0.79, in: size), control1: point(0.29, 0.67, in: size), control2: point(0.67, 0.94, in: size))
        return [moon, thread]
    }

    private func ribbon(in size: CGSize) -> [Path] {
        var first = Path()
        first.move(to: point(0.03, 0.72, in: size))
        first.addCurve(to: point(0.97, 0.3, in: size), control1: point(0.31, 0.02, in: size), control2: point(0.68, 0.97, in: size))

        var second = Path()
        second.move(to: point(0.04, 0.42, in: size))
        second.addCurve(to: point(0.96, 0.64, in: size), control1: point(0.3, 0.93, in: size), control2: point(0.72, 0.02, in: size))
        return [first, second]
    }
}

#Preview("Editorial sketches") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            EditorialSketchView(scene: .profiles).frame(height: 190)
            EditorialSketchView(scene: .almostTouching, wash: Palette.paper).frame(height: 190)
            EditorialSketchView(scene: .handOnHeart).frame(height: 190)
            EditorialSketchView(scene: .threshold, wash: Palette.softRose).frame(height: 190)
            EditorialSketchView(scene: .bloom).frame(height: 190)
            EditorialSketchView(scene: .moonThread, wash: Palette.paper).frame(height: 190)
        }
        .padding()
    }
    .background(Palette.canvas)
}
