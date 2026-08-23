import Foundation
import Observation

// MARK: - AppState
//
// Top-level phase machine. `firstRun` shows the welcome arc; `active` is the
// living app. Phase transitions are driven by real state in EmberStore.

@MainActor
@Observable
final class AppState {

    nonisolated enum Phase: Equatable, Sendable {
        case firstRun
        case active
    }

    private(set) var phase: Phase

    init(hasJourney: Bool = false) {
        self.phase = hasJourney ? .active : .firstRun
    }

    /// Called when the user finishes choosing a journey (onboarding done).
    func activate() {
        phase = .active
    }

    /// Called after "begin a different journey" wipes state.
    func resetToFirstRun() {
        phase = .firstRun
    }

    // MARK: Derived session context (non-persisted)

    /// The next day to live, derived from completed days — suggests pacing
    /// without ever shaming the user.
    func suggestedDayNumber(completedDays: [Int]) -> Int {
        min(JourneyCatalog.totalDays, (completedDays.max() ?? 0) + 1)
    }
}
