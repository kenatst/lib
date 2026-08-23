import CoreGraphics

// MARK: - Sketch geometry (pure, testable)
//
// All motifs live in normalized space [0…1 × 0…1] and are rendered by
// SketchMotifView. Every curve is a sampled polyline with a deterministic
// hand-tremor so the same pose always draws identically (no shimmer).

nonisolated enum SketchCurve {

    /// Sampled polylines (in normalized space) for a journey motif.
    /// `evolution` ∈ 0…1 morphs the pose across the 21-day journey.
    static func strokes(journey: DesireIntention, evolution: Double, seed: UInt64 = 11) -> [[CGPoint]] {
        switch journey {
        case .myDesire: return myDesire(evolution: evolution, seed: seed)
        case .theirDesire: return theirDesire(evolution: evolution, seed: seed)
        case .ourDesire: return ourDesire(evolution: evolution, seed: seed)
        }
    }

    /// Small secondary marks (hatches, tension dashes) drawn around the motif.
    /// Each entry: (start, end, relativeOpacity).
    static func marks(journey: DesireIntention, evolution: Double, seed: UInt64 = 23) -> [(CGPoint, CGPoint, Double)] {
        switch journey {
        case .myDesire: return myDesireMarks(evolution: evolution, seed: seed)
        case .theirDesire: return theirDesireMarks(evolution: evolution, seed: seed)
        case .ourDesire: return ourDesireMarks(evolution: evolution, seed: seed)
        }
    }

    // MARK: MY DESIRE — one form returning toward itself

    private static func myDesire(evolution e: Double, seed: UInt64) -> [[CGPoint]] {
        let samples = 140
        let sweep = 4.30 + 1.55 * e                 // radians travelled
        let baseRadius = 0.315 - 0.075 * e          // slowly settling inward
        var pts: [CGPoint] = []
        pts.reserveCapacity(samples)
        for i in 0..<samples {
            let t = Double(i) / Double(samples - 1)
            let angle = -0.9 + sweep * t            // unwinds clockwise
            // Radius breathes slightly along the stroke so it reads organic.
            let r = baseRadius * (1.0 + 0.06 * sin(angle * 2.1 + 0.7)) * (1.0 - 0.16 * t * (0.4 + e))
            var p = CGPoint(x: 0.5 + r * cos(angle), y: 0.52 + r * sin(angle))
            p = wobble(p, index: i, amount: 0.007, seed: seed)
            pts.append(p)
        }
        return [pts]
    }

    private static func myDesireMarks(evolution e: Double, seed: UInt64) -> [(CGPoint, CGPoint, Double)] {
        // Inner ember: a short arc near the center, appearing as the form returns.
        guard e > 0.28 else { return [] }
        let strength = min(1, (e - 0.28) / 0.4)
        let samples = 24
        var arc: [CGPoint] = []
        for i in 0..<samples {
            let t = Double(i) / Double(samples - 1)
            let angle = 2.4 + 1.5 * t
            let r = 0.075
            var p = CGPoint(x: 0.48 + r * cos(angle), y: 0.53 + r * sin(angle))
            p = wobble(p, index: i + 40, amount: 0.004, seed: seed)
            arc.append(p)
        }
        // Rendered as dense short segments so it fades in like graphite pressure.
        return stride(from: 0, to: arc.count - 1, by: 2).map { i in
            (arc[i], arc[i + 1], 0.35 * strength)
        }
    }

    // MARK: THEIR DESIRE — two independent forms, charged space between

    private static func theirDesire(evolution e: Double, seed: UInt64) -> [[CGPoint]] {
        let gap = 0.17 - 0.105 * e                  // approaches, never touches
        let bulge = 0.20
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        let samples = 90
        for i in 0..<samples {
            let t = Double(i) / Double(samples - 1)
            let s = sin(.pi * t)
            let leanL = 0.035 * (t - 0.5)
            var pl = CGPoint(x: 0.5 - gap / 2 - bulge * pow(s, 1.15) + leanL,
                             y: 0.22 + 0.56 * t)
            var pr = CGPoint(x: 0.5 + gap / 2 + bulge * pow(s, 1.15) - leanL,
                             y: 0.78 - 0.56 * t)     // mirrored vertically: two distinct characters
            pl = wobble(pl, index: i, amount: 0.006, seed: seed &+ 101)
            pr = wobble(pr, index: i + 7, amount: 0.006, seed: seed &+ 202)
            left.append(pl)
            right.append(pr)
        }
        return [left, right]
    }

    private static func theirDesireMarks(evolution e: Double, seed: UInt64) -> [(CGPoint, CGPoint, Double)] {
        // Tension dashes across the gap — shorten as the forms approach.
        let gap = 0.17 - 0.105 * e
        let dashLength = gap * 0.62
        let rows: [Double] = [0.36, 0.5, 0.64]
        return rows.enumerated().map { idx, y in
            let jitter = noise(index: idx, seed: seed) * 0.02
            let start = CGPoint(x: 0.5 - dashLength / 2 + jitter, y: y + jitter * 0.4)
            let end = CGPoint(x: 0.5 + dashLength / 2 + jitter, y: y - jitter * 0.4)
            return (start, end, 0.5 - 0.25 * e)
        }
    }

    // MARK: OUR DESIRE — two lines weaving while remaining distinct

    private static func ourDesire(evolution e: Double, seed: UInt64) -> [[CGPoint]] {
        let phaseShift = 0.35 * .pi * e             // progressive interlacing
        let separation = 0.13 - 0.03 * e            // gentle convergence
        let amplitude = 0.085 + 0.02 * e
        var upper: [CGPoint] = []
        var lower: [CGPoint] = []
        let samples = 150
        for i in 0..<samples {
            let t = Double(i) / Double(samples - 1)
            let x = 0.10 + 0.80 * t
            let envelope = sin(.pi * t)             // lines fade at their ends
            var pu = CGPoint(x: x,
                             y: 0.5 - separation / 2 - amplitude * envelope * cos(2.2 * .pi * t + phaseShift))
            var pl = CGPoint(x: x,
                             y: 0.5 + separation / 2 + amplitude * envelope * cos(2.2 * .pi * t - phaseShift + 0.9))
            pu = wobble(pu, index: i, amount: 0.005, seed: seed &+ 303)
            pl = wobble(pl, index: i + 13, amount: 0.005, seed: seed &+ 404)
            upper.append(pu)
            lower.append(pl)
        }
        return [upper, lower]
    }

    private static func ourDesireMarks(evolution e: Double, seed: UInt64) -> [(CGPoint, CGPoint, Double)] {
        // Tiny ember dashes appear where the lines weave closest.
        let crossings = Int((e * 2.6).rounded())
        return (0..<crossings).map { k in
            let t = Double(k + 1) / Double(crossings + 1)
            let x = 0.10 + 0.80 * t
            let y = 0.5 + noise(index: k, seed: seed) * 0.04 - 0.02
            let len = 0.014
            return (
                CGPoint(x: x - len / 2, y: y),
                CGPoint(x: x + len / 2, y: y - 0.006),
                0.45
            )
        }
    }

    // MARK: Deterministic helpers

    /// Hand tremor: smooth pseudo-noise, identical for identical inputs.
    static func wobble(_ p: CGPoint, index: Int, amount: Double, seed: UInt64) -> CGPoint {
        let n1 = noise(index: index, seed: seed)
        let n2 = noise(index: index &+ 7919, seed: seed &+ 5501)
        return CGPoint(x: p.x + (n1 - 0.5) * amount * 2,
                       y: p.y + (n2 - 0.5) * amount * 2)
    }

    static func noise(index: Int, seed: UInt64) -> Double {
        var h = UInt64(truncatingIfNeeded: index) &* 374761393 &+ seed &* 668265263
        h = (h ^ (h >> 13)) &* 1274126177
        h ^= h >> 16
        return Double(h % 100_000) / 100_000
    }
}
