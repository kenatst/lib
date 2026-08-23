import Foundation
import Testing
@testable import Ember

// MARK: - BUG REPRODUCTION (pre-fix): stranded days under real adaptation
//
// The cursor is max(completedDays)+1 while adaptation may pick from
// next…next+3. Completing an adapted-forward day jumps the cursor past every
// uncompleted day between. This suite MUST fail before the fix and pass after.

@Suite("BUG REPRO — stranded days (must fail pre-fix, pass post-fix)")
struct StrandedDayReproductionTests {

    @Test("Repro: raised intensity adapts forward and strands the skipped days")
    func noStrandingWithAdaptation() {
        // THEIR shape around day 2: [attention, communication, attention,
        // body, anticipation, …]. A wantMore evening makes day 5
        // (anticipation, +2) beat day 2 — the cursor then jumps to 6.
        var completed: [Int] = [1]
        var served: [Int] = [1]

        while completed.count < JourneyCatalog.totalDays {
            guard let rec = JourneyPlanner.recommend(
                intention: .theirDesire,
                profile: nil,
                completedDays: completed,
                checkIns: [CheckIn(dayNumber: served.last ?? 1, response: .wantMore, date: .now)]
            ) else { break }
            served.append(rec.dayNumber)
            completed.append(rec.dayNumber)
            completed.sort()
        }

        let missing = Set(1...JourneyCatalog.totalDays).subtracting(Set(served))
        #expect(missing.isEmpty, "stranded forever: \(missing.sorted()) — served \(served)")
    }
}
