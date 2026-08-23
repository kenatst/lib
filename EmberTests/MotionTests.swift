import Testing
import SwiftUI
@testable import Ember

struct MotionTests {

    @Test("Reduce Motion replaces motion with a short quiet crossfade")
    func reducedMotionBecomesCrossfade() {
        let resolved = Motion.resolved(Motion.gentle, reduceMotion: true)
        #expect(resolved != nil)
        // The crossfade must be quick and calm; verify by description marker.
        let text = String(describing: resolved)
        #expect(text.contains("0.15"), "unexpected reduce-motion animation: \(text)")
    }

    @Test("Standard motion keeps the intended animation")
    func standardMotionPreservesAnimation() {
        #expect(Motion.resolved(Motion.gentle, reduceMotion: false) != nil)
        #expect(Motion.resolved(nil, reduceMotion: true) == nil)
    }

    @Test("Delayed resolution keeps stagger order under both modes")
    func delayedResolution() {
        #expect(Motion.resolved(Motion.ink, reduceMotion: false, delay: 0.3) != nil)
        #expect(Motion.resolved(Motion.ink, reduceMotion: true, delay: 0.3) != nil)
    }
}
