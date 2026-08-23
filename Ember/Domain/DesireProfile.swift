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

        // Order: strongest signal first (by |strength|), stable tie-break by
        // declaration order so derivation is deterministic.
        let declaredOrder = Dimension.allCases
        readings.sort { lhs, rhs in
            let l = abs(lhs.strength)
            let r = abs(rhs.strength)
            if l != r { return l > r }
            return declaredOrder.firstIndex(of: lhs.dimension)! < declaredOrder.firstIndex(of: rhs.dimension)!
        }

        // Guarantee every core dimension has a reading so no paragraph is missing.
        for dimension in Dimension.allCases where !readings.contains(where: { $0.dimension == dimension }) {
            // Unasked dimensions get a neutral reading only if some other
            // journey asked about them indirectly; otherwise omitted.
            continue
        }

        return DesireProfile(readings: readings, intention: intention)
    }
}
