import Testing
@testable import Ember

@MainActor
struct AppRouterTests {

    @Test("A fresh router exposes an empty navigation path")
    func freshRouterHasEmptyPath() {
        let router = AppRouter()
        #expect(router.path.isEmpty)
    }

    @Test("Navigation appends typed routes while preserving order")
    func navigationPreservesRouteOrder() {
        let router = AppRouter()
        router.navigate(to: .intentionOverview(.myDesire))
        router.navigate(to: .intentionOverview(.ourDesire))
        #expect(
            router.path == [
                .intentionOverview(.myDesire),
                .intentionOverview(.ourDesire),
            ]
        )
    }

    @Test("Routes carrying different intentions remain distinct")
    func routePayloadsArePartOfIdentity() {
        #expect(AppRoute.intentionOverview(.myDesire) != AppRoute.intentionOverview(.theirDesire))
    }

    @Test("Popping removes only the topmost route")
    func poppingRemovesOnlyTopmostRoute() {
        let router = AppRouter()
        router.navigate(to: .intentionOverview(.myDesire))
        router.navigate(to: .intentionOverview(.theirDesire))

        router.pop()

        #expect(router.path == [.intentionOverview(.myDesire)])
    }

    @Test("Popping an empty path is a safe no-op")
    func poppingEmptyPathNeverTraps() {
        let router = AppRouter()
        router.pop()
        #expect(router.path.isEmpty)
    }

    @Test("Returning to the root clears every pushed destination")
    func returningToRootClearsPath() {
        let router = AppRouter()
        router.navigate(to: .intentionOverview(.myDesire))
        router.navigate(to: .intentionOverview(.ourDesire))

        router.popToRoot()

        #expect(router.path.isEmpty)
    }
}
