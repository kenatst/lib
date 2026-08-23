import SwiftUI

/// The EMBER page surface: warm canvas with a faint procedural paper grain.
struct PaperBackground: View {

    var tint: Color = Palette.canvas

    @Environment(\.colorScheme) private var colorScheme
    @State private var seed: Int = 7

    var body: some View {
        ZStack {
            Rectangle().fill(tint)
            Canvas { context, size in
                let count = Int(size.width * size.height / 2600)
                var generator = SeededRandom(seed: UInt64(seed))
                for _ in 0..<max(40, count) {
                    let x = generator.nextDouble() * size.width
                    let y = generator.nextDouble() * size.height
                    let radius = generator.nextDouble() * 1.1 + 0.3
                    let alpha = generator.nextDouble() * 0.05 + 0.015
                    let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                    context.opacity = alpha
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Palette.mutedInk)
                    )
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    /// Deterministic PRNG so the grain doesn't shimmer between renders of the
    /// same layout pass (SwiftUI may re-invoke the Canvas closure).
    struct SeededRandom {
        private var state: UInt64
        init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
        mutating func nextDouble() -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Double(state >> 11) / Double(1 << 53)
        }
    }
}

#Preview("Paper") {
    PaperBackground()
}
