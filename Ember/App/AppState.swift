import Observation

@Observable
final class AppState {

    nonisolated enum Phase: Equatable, Sendable {
        case onboarding
        case active
    }

    private(set) var phase: Phase = .onboarding

    func completeOnboarding() {
        phase = .active
    }
}
