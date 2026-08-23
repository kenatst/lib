import SwiftUI

// MARK: - Motion vocabulary
//
// Motion should feel like breathing, ink appearing, approaching. Slow,
// weighted, quiet. Reduce Motion replaces every animation with a crossfade.

enum Motion {

    /// Standard interactive transition — approaching.
    static let gentle: Animation = .smooth(duration: 0.45)
    /// Narrative reveals — ink appearing on paper.
    static let ink: Animation = .easeInOut(duration: 0.9)
    /// Large scene changes — breathing.
    static let breathe: Animation = .smooth(duration: 1.1)
    /// Spring with almost no bounce; settles like a held breath releasing.
    static let settle: Animation = .spring(duration: 0.7, bounce: 0.06)

    /// Resolves an animation against Reduce Motion. Always route animations
    /// through this; never apply raw `Animation` values in features.
    static func resolved(_ animation: Animation?, reduceMotion: Bool) -> Animation? {
        guard let animation else { return nil }
        return reduceMotion ? .linear(duration: 0.15) : animation
    }

    /// Convenience for staggered reveals that still respects Reduce Motion.
    static func resolved(_ animation: Animation?, reduceMotion: Bool, delay: TimeInterval) -> Animation? {
        let base = resolved(animation, reduceMotion: reduceMotion)
        return base?.delay(delay)
    }
}
