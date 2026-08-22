import Foundation
import Testing
@testable import Ember

struct DesireIntentionTests {

    @Test("The product offers exactly the three defined journeys")
    func exposesExactlyThreeIntentions() {
        #expect(DesireIntention.allCases.count == 3)
    }

    @Test("Raw values are stable identifiers for future persistence and pairing")
    func rawValuesAreStableIdentifiers() {
        #expect(DesireIntention.allCases.map(\.rawValue) == ["myDesire", "theirDesire", "ourDesire"])
    }

    @Test("Intentions survive a Codable round trip unchanged")
    func codableRoundTripPreservesIntention() throws {
        for intention in DesireIntention.allCases {
            let data = try JSONEncoder().encode(intention)
            let decoded = try JSONDecoder().decode(DesireIntention.self, from: data)
            #expect(decoded == intention)
        }
    }
}
