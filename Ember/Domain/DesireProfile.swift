import Foundation

// MARK: - Desire Profile
//
// A qualitative portrait derived from onboarding answers. Never numeric,
// never shown as scores. Dimensions are ordered by how strongly they
// characterize the user; the top ones shape which days are emphasized.

nonisolated enum Dimension: String, Codable, CaseIterable, Sendable {
    case anticipation
    case connection
    case novelty
    case autonomy
    case selfConnection
    case confidence
    case playfulness
    case communication
    case emotionalSafety

    /// Localization keys: "profile.dim.<rawValue>.opening|middle|rich"
    var openingKey: String { "profile.dim.\(rawValue).opening" }
    var middleKey: String { "profile.dim.\(rawValue).middle" }
    var richKey: String { "profile.dim.\(rawValue).rich" }
}

nonisolated struct DimensionReading: Equatable, Codable, Sendable {
    let dimension: Dimension
    /// -1 … +1 relative strength vs. the neutral midpoint.
    let strength: Double

    var band: Band {
        switch strength {
        case ..<(-0.25): .guarded
        case -0.25..<0.35: .middle
        default: .rich
        }
    }

    nonisolated enum Band: String, Sendable {
        case guarded, middle, rich
    }
}

nonisolated struct DesireProfile: Equatable, Codable, Sendable {

    /// Ordered strongest-first.
    let readings: [DimensionReading]
    let intention: DesireIntention

    func reading(_ dimension: Dimension) -> DimensionReading? {
        readings.first { $0.dimension == dimension }
    }

    /// The two most defining dimensions — they steer day emphasis.
    var dominant: [Dimension] {
        Array(readings.prefix(2).map(\.dimension))
    }
}

// MARK: - Derivation

nonisolated enum DesireProfileDeriver {

    /// Derives a qualitative profile from onboarding answers.
    /// Pure function: same answers → same profile (heavily tested).
    static func derive(from responses: Onboarding.Responses, intention: DesireIntention) -> DesireProfile {
        var totals: [Dimension: Double] = [:]
        var counts: [Dimension: Double] = [:]

        for questionID in responses.order {
            guard let option = responses.option(for: questionID) else { continue }
            totals[option.dimension, default: 0] += Double(option.score)
            counts[option.dimension, default: 0] += 1
        }

        // Normalize each dimension to roughly [-1…1]. A single answer's max
        // magnitude is 3; multiple answers average then widen slightly.
        var readings: [DimensionReading] = []
        for (dimension, total) in totals {
            let count = max(counts[dimension] ?? 1, 1)
            let average = total / count
            let strength = max(-1, min(1, average / 2))
            readings.append(DimensionReading(dimension: dimension, strength: strength))
        }

        // Editorial order: rich strengths lead, middle follows, guarded
        // ("growth areas") close gently. Ties break by declaration order so
        // derivation stays deterministic.
        let declaredOrder = Dimension.allCases
        func rank(_ r: DimensionReading) -> Int {
            switch r.band {
            case .rich: 0
            case .middle: 1
            case .guarded: 2
            }
        }
        readings.sort { lhs, rhs in
            let l = rank(lhs)
            let r = rank(rhs)
            if l != r { return l < r }
            if lhs.strength != rhs.strength { return abs(lhs.strength) > abs(rhs.strength) }
            return declaredOrder.firstIndex(of: lhs.dimension)! < declaredOrder.firstIndex(of: rhs.dimension)!
        }

        return DesireProfile(readings: readings, intention: intention)
    }
}
