import Observation

// MARK: - Typed routes
//
// One enum drives all navigation. Routes are value types carrying payloads,
// Hashable for NavigationStack, Sendable for testability.

nonisolated enum AppRoute: Hashable, Sendable {
    case journeySelection
    case onboarding(DesireIntention)
    case desireProfile
    case home

    // ONGOING IDENTITY (004B): routes carry the frozen session ID — never a
    // course number. Reopening today's session always lands on THIS session.
    case dailySession(String)
    case eveningReturn(String)

    /// LEGACY numbered routes. Kept solely so migration-era deep links and
    /// DEBUG seeding still resolve; no ongoing flow may navigate through them.
    case day(Int)
    case eveningReturnLegacy(Int)

    case progress
    case journal
    case settings
    case coupleSetup
    case coupleSpace
    case paywall
}

// MARK: - Router

@Observable
final class AppRouter {

    var path: [AppRoute] = []

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    /// Replaces the whole stack — used when jumping between major scenes
    /// (e.g. finishing onboarding lands on Home with no back trail).
    func setRoot(_ route: AppRoute) {
        path = [route]
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
