import SwiftUI

@main
struct EmberApp: App {

    @State private var appState = AppState()
    @State private var router = AppRouter()

    init() {
        EmberLog.app.info("Ember launching")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(router)
                .tint(Palette.wine)
        }
    }
}
