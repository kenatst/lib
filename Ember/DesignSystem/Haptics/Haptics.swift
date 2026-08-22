import UIKit

enum Haptics {

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
