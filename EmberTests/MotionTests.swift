import Testing
@testable import Ember

struct MotionTests {

    @Test("Reduce Motion suppresses implicit animation entirely")
    func reducedMotionSuppressesAnimation() {
        #expect(Motion.resolved(Motion.gentle, reduceMotion: true) == nil)
    }

    @Test("Standard motion keeps the intended animation")
    func standardMotionPreservesAnimation() {
        #expect(Motion.resolved(Motion.gentle, reduceMotion: false) != nil)
    }
}
