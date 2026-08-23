import SwiftUI

@main
struct EmberApp: App {

    @State private var store: EmberStore
    @State private var appState: AppState
    @State private var router = AppRouter()

    init() {
        let store = EmberStore()
        let appState = AppState(hasJourney: store.hasJourney)
        let router = AppRouter()
        _store = State(initialValue: store)
        _appState = State(initialValue: appState)
        _router = State(initialValue: router)
        #if DEBUG
        DemoLauncher.apply(store: store, appState: appState, router: router)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(appState)
                .environment(router)
                .tint(Palette.accent)
                .preferredColorScheme(.light)
        }
    }
}
