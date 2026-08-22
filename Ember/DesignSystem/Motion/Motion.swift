import SwiftUI

enum Motion {

    static let gentle = Animation.smooth(duration: 0.45)

    static func resolved(_ animation: Animation?, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}
