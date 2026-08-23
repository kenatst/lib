import CoreGraphics
import Foundation
import Testing
@testable import Ember

// MARK: - Sketch geometry (deterministic illustration engine)

@MainActor
@Suite("SketchCurve geometry")
struct SketchCurveTests {

    @Test("All strokes are sampled, finite and inside normalized bounds")
    func strokesWellFormed() {
        for journey in DesireIntention.allCases {
            for evolution in [0.0, 0.25, 0.5, 0.75, 1.0] {
                let strokes = SketchCurve.strokes(journey: journey, evolution: evolution)
                #expect(!strokes.isEmpty)
                for stroke in strokes {
                    #expect(stroke.count > 20, "stroke too sparse for smooth rendering")
                    for p in stroke {
                        #expect(p.x.isFinite && p.y.isFinite)
                        // Wobble may push a point marginally outside [0…1]; allow slack.
                        #expect(p.x > -0.05 && p.x < 1.05)
                        #expect(p.y > -0.05 && p.y < 1.05)
                    }
                }
            }
        }
    }

    @Test("MY DESIRE evolves: the form sweeps further as the journey progresses")
    func myDesireEvolution() {
        let early = SketchCurve.strokes(journey: .myDesire, evolution: 0.05)[0]
        let late = SketchCurve.strokes(journey: .myDesire, evolution: 0.95)[0]
        let angularSpan = { (pts: [CGPoint]) -> Double in
            pts.map { atan2(Double($0.y - 0.52), Double($0.x - 0.5)) }
                .sorted()
                .letFirstMinusLast
        }
        _ = angularSpan // (kept local; direct assertion below)
        let lateSweep = late.count
        let earlySweep = early.count
        #expect(lateSweep == earlySweep) // sampling density constant
        // The final point travels further around the center.
        let firstAngle = atan2(Double(early.last!.y - 0.52), Double(early.last!.x - 0.5))
        let lastAngle = atan2(Double(late.last!.y - 0.52), Double(late.last!.x - 0.5))
        #expect(abs(lastAngle - firstAngle) > 0.1)
    }

    @Test("THEIR DESIRE approaches but never touches")
    func theirDesireNeverTouches() {
        for evolution in stride(from: 0.0, through: 1.0, by: 0.1) {
            let strokes = SketchCurve.strokes(journey: .theirDesire, evolution: evolution)
            #expect(strokes.count == 2, "two distinct forms required")
            let left = strokes[0]
            let right = strokes[1]
            // At matching heights, the gap must stay strictly positive.
            for i in stride(from: 0, to: left.count, by: 9) {
                let l = left[i]
                let r = right[right.count - 1 - i] // mirrored counterpart
                let horizontalGap = abs(r.x - l.x)
                #expect(horizontalGap > 0.01, "gap collapsed at evolution \(evolution)")
            }
            // And the overall minimum distance shrinks as evolution rises.
        }
        func minGap(evolution: Double) -> Double {
            let s = SketchCurve.strokes(journey: .theirDesire, evolution: evolution)
            return zip(s[0], s[1].reversed()).map { abs($1.x - $0.x) }.min() ?? .infinity
        }
        #expect(minGap(evolution: 0.9) < minGap(evolution: 0.1))
    }

    @Test("OUR DESIRE stays two distinct lines that weave closer")
    func ourDesireWeaves() {
        let early = SketchCurve.strokes(journey: .ourDesire, evolution: 0.05)
        let late = SketchCurve.strokes(journey: .ourDesire, evolution: 0.95)
        #expect(early.count == 2 && late.count == 2)
        func meanSeparation(_ pair: [[CGPoint]]) -> Double {
            zip(pair[0], pair[1]).map { abs(Double($1.y - $0.y)) }.reduce(0, +) / Double(pair[0].count)
        }
        #expect(meanSeparation(late) < meanSeparation(early))

        // Marks (weaving embers) increase with evolution.
        let earlyMarks = SketchCurve.marks(journey: .ourDesire, evolution: 0.2).count
        let lateMarks = SketchCurve.marks(journey: .ourDesire, evolution: 0.95).count
        #expect(lateMarks > earlyMarks)
    }

    @Test("Determinism: identical inputs produce identical geometry (no shimmer)")
    func deterministic() {
        for journey in DesireIntention.allCases {
            let a = SketchCurve.strokes(journey: journey, evolution: 0.42, seed: 11)
            let b = SketchCurve.strokes(journey: journey, evolution: 0.42, seed: 11)
            #expect(a == b)
            let ma = SketchCurve.marks(journey: journey, evolution: 0.42, seed: 23)
            let mb = SketchCurve.marks(journey: journey, evolution: 0.42, seed: 23)
            #expect(ma.map { "\($0.0)-\($0.1)-\($0.2)" } == mb.map { "\($0.0)-\($0.1)-\($0.2)" })
        }
    }

    @Test("Noise is stable across calls and within unit range")
    func noiseStability() {
        for i in 0..<500 {
            let n = SketchCurve.noise(index: i, seed: 99)
            #expect(n >= 0 && n < 1)
            #expect(n == SketchCurve.noise(index: i, seed: 99))
        }
    }

    @Test("Palette semantic tokens decode to the specified hex values")
    func paletteValues() {
        func rgba(_ color: CGColor) -> [CGFloat] {
            let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
            let converted = color.converted(to: sRGB, intent: .relativeColorimetric, options: nil)!
            return converted.components!.map { CGFloat($0) }
        }
        // Canvas #FFF8F5
        let canvas = rgba(Palette.canvas.cgColor!)
        #expect(abs(canvas[0] - 1.0) < 0.002)
        #expect(abs(canvas[1] - 248/255) < 0.002)
        #expect(abs(canvas[2] - 245/255) < 0.002)
        // Ink #28171E
        let ink = rgba(Palette.ink.cgColor!)
        #expect(abs(ink[0] - 40/255) < 0.002)
        #expect(abs(ink[1] - 23/255) < 0.002)
        #expect(abs(ink[2] - 30/255) < 0.002)
        // Wine #6A243B
        let wine = rgba(Palette.wine.cgColor!)
        #expect(abs(wine[0] - 106/255) < 0.002)
        #expect(abs(wine[1] - 36/255) < 0.002)
        #expect(abs(wine[2] - 59/255) < 0.002)
    }
}

private extension Array where Element == Double {
    var letFirstMinusLast: Double { (first ?? 0) - (last ?? 0) }
}
