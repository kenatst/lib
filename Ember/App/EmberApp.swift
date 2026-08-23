import SwiftUI

@main
struct EmberApp: App {

    @State private var store: EmberStore
    @State private var appState: AppState
    @State private var router = AppRouter()

    init() {
        let store = EmberStore()
        _store = State(initialValue: store)
        _appState = State(initialValue: AppState(hasJourney: store.hasJourney))
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
