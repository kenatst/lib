import UIKit

// MARK: - Haptics
//
// Used sparingly: one signal per meaningful moment. Selection ticks for
// choices, a soft success at day completion, a gentle notice when something
// private is saved. Never fire in loops or decoration.

enum Haptics {

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// A quiet acknowledgment — saving a reflection, completing a step.
    static func soft() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// A low, warm pulse for charged moments (day complete, journey milestones).
    static func warm() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: 0.7)
    }
}
