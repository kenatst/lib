import Observation

nonisolated enum AppRoute: Hashable, Sendable {
    case intentionOverview(DesireIntention)
}

@Observable
final class AppRouter {

    var path: [AppRoute] = []

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
