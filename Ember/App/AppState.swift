import Foundation
import Observation

// MARK: - AppState
//
// Top-level phase machine. `ageGate` is the one-time adult confirmation,
// `firstRun` shows the welcome arc, `active` is the living app. Phase
// transitions are driven by real state in EmberStore.

@MainActor
@Observable
final class AppState {

    nonisolated enum Phase: Equatable, Sendable {
        case ageGate
        case firstRun
        case active
    }

    private(set) var phase: Phase

    init(hasJourney: Bool = false, ageConfirmed: Bool = false) {
        if hasJourney {
            // Returning user; the gate ran when their journey was created.
            self.phase = .active
            self.hasConfirmedAge = ageConfirmed
        } else {
            self.hasConfirmedAge = ageConfirmed
            self.phase = ageConfirmed ? .firstRun : .ageGate
        }
    }

    /// Called after the 18+ confirmation.
    func confirmAge() {
        hasConfirmedAge = true
        if phase == .ageGate { phase = .firstRun }
    }

    /// Called when the user finishes choosing a journey (onboarding done).
    func activate() {
        phase = .active
    }

    /// Called after "begin a different journey" wipes state.
    func resetToFirstRun() {
        phase = hasConfirmedAge ? .firstRun : .ageGate
    }

    private var hasConfirmedAge = false

    // MARK: Derived session context (non-persisted)

    /// Legacy numbered-day helper retained only for migration-era views.
    /// The ongoing engine derives "today" from the calendar, not counters.
    func suggestedDayNumber(completedDays: [Int]) -> Int {
        min(JourneyCatalog.totalDays, (completedDays.max() ?? 0) + 1)
    }
}
