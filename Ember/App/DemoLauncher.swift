import Foundation

// MARK: - Demo launcher (DEBUG only)
//
// Lets tools and humans open any screen in a defined state via launch
// arguments, e.g.:
//   xcrun simctl launch <udid> com.kenatst.ember \
//       -ember-intention ourDesire -ember-completed 9 -ember-route progress
//
// Inert in production builds and without arguments.

#if DEBUG
@MainActor
enum DemoLauncher {

    static func apply(store: EmberStore, appState: AppState, router: AppRouter) {
        let args = ProcessInfo.processInfo.arguments

        func value(_ key: String) -> String? {
            guard let index = args.firstIndex(of: key), index + 1 < args.count else { return nil }
            return args[index + 1]
        }

        // Seed journey + profile.
        if value("-ember-fresh") != nil {
            store.deleteEverything()
        }
        if let rawIntention = value("-ember-intention") {
            let intention = DesireIntention(rawValue: rawIntention) ?? .myDesire
            store.setIntention(intention)
            var responses = Onboarding.Responses()
            for question in Onboarding.questions(for: intention) {
                if let option = question.options.first {
                    responses.record(.init(questionID: question.id, optionID: option.id))
                }
            }
            store.recordResponses(responses)
            store.setProfile(DesireProfileDeriver.derive(from: responses, intention: intention))
        }

        if let coupleRole = value("-ember-role") {
            store.setCoupleRole(coupleRole == "two" ? .partnerTwo : .partnerOne)
        }

        // Mark days complete (and give a couple of them reflections). Also
        // seeds the ongoing engine's legacy-migrated history via migration.
        if let completed = Int(value("-ember-completed") ?? "") {
            for day in 1...max(0, min(completed, JourneyCatalog.totalDays)) {
                store.markDayComplete(day)
            }
            if completed >= 3 {
                store.saveReflection("Something softened tonight, quietly.", day: 2)
            }
        }

        // Seed an evening check-in (for pacing-note verification). Runs after
        // completion seeding so the check-in lands on the last finished day.
        if let checkin = value("-ember-checkin") {
            let day = max(1, store.state.completedDays.count)
            let response: CheckInResponse
            switch checkin {
            case "nothing": response = .nothingChanged
            case "noticed": response = .noticedSomething
            case "wantMore": response = .wantMore
            default: response = .feltDifferent
            }
            store.recordCheckIn(CheckIn(dayNumber: day, response: response, date: .now))
        }

        if let handedOff = value("-ember-handoff") {
            let role: EmberStore.CoupleRole = (value("-ember-role") == "two") ? .partnerTwo : .partnerOne
            store.handOffNote(handedOff, from: role.other)
        }

        // Freeze today's plan so QA sees exactly what users see.
        _ = store.planForToday()

        // Open a specific scene.
        if let route = value("-ember-route") {
            applyRoute(route, store: store, appState: appState, router: router)
            return
        }

        // Fallback when launch arguments aren't delivered (some simctl/host
        // combinations drop them): read the same instructions from a file in
        // Application Support. Lines of key=value:
        //   intention=myDesire|theirDesire|ourDesire
        //   completed=<n>   checkin=nothing|noticed|feltDifferent|wantMore
        //   role=one|two    route=<same values as -ember-route>
        applyDemoFile(store: store, appState: appState, router: router)
    }

    private static func applyDemoFile(store: EmberStore, appState: AppState, router: AppRouter) {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let file = appSupport
            .appendingPathComponent("Ember", isDirectory: true)
            .appendingPathComponent("demo-instructions.txt")
        guard let raw = try? String(contentsOf: file, encoding: .utf8) else { return }
        try? fm.removeItem(at: file)   // one-shot

        var vars: [String: String] = [:]
        for line in raw.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            vars[String(parts[0]).trimmingCharacters(in: .whitespaces)] =
                String(parts[1]).trimmingCharacters(in: .whitespaces)
        }

        if let fresh = vars["fresh"], fresh == "true" {
            store.deleteEverything()
        }
        // Debug language override (set before any view renders, so it takes
        // effect this run). Used solely for FR layout QA.
        if let lang = vars["lang"] {
            UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        }
        if let rawIntention = vars["intention"], let intention = DesireIntention(rawValue: rawIntention) {
            store.setIntention(intention)
            var responses = Onboarding.Responses()
            for question in Onboarding.questions(for: intention) {
                if let option = question.options.first {
                    responses.record(.init(questionID: question.id, optionID: option.id))
                }
            }
            store.recordResponses(responses)
            store.setProfile(DesireProfileDeriver.derive(from: responses, intention: intention))
        }
        if let role = vars["role"] {
            store.setCoupleRole(role == "two" ? .partnerTwo : .partnerOne)
        }
        if let completed = Int(vars["completed"] ?? "") {
            for day in 1...max(0, min(completed, JourneyCatalog.totalDays)) {
                store.markDayComplete(day)
            }
            if completed >= 2 {
                store.saveReflection("Something softened tonight, quietly.", day: 2)
            }
        }
        if let checkin = vars["checkin"] {
            let day = max(1, store.state.completedDays.count)
            let response: CheckInResponse
            switch checkin {
            case "nothing": response = .nothingChanged
            case "noticed": response = .noticedSomething
            case "wantMore": response = .wantMore
            default: response = .feltDifferent
            }
            store.recordCheckIn(CheckIn(dayNumber: day, response: response, date: .now))
        }
        if let handoff = vars["handoff"] {
            let role: EmberStore.CoupleRole = (vars["role"] == "two") ? .partnerTwo : .partnerOne
            store.handOffNote(handoff, from: role.other)
        }
        if let route = vars["route"] {
            applyRoute(route, store: store, appState: appState, router: router)
        } else {
            appState.activate()
        }
    }

    private static func applyRoute(_ route: String, store: EmberStore, appState: AppState, router: AppRouter) {
        appState.activate()
        switch route {
        case "welcome":
            break
        case "selection":
            router.setRoot(.journeySelection)
        case "onboarding":
            let intention = DesireIntention(rawValue: ProcessInfo.processInfo.environment["EMBER_INTENTION"] ?? "") ?? .myDesire
            router.setRoot(.onboarding(intention))
        case "profile":
            router.setRoot(.desireProfile)
        case "day":
            let day = Int(ProcessInfo.processInfo.environment["EMBER_DAY"] ?? "") ?? (store.state.completedDays.max() ?? 0) + 1
            router.setRoot(.dailySession(store.currentPlanID ?? "debug"))
        case "return":
            let day = Int(ProcessInfo.processInfo.environment["EMBER_DAY"] ?? "") ?? max(1, store.state.completedDays.count)
            router.setRoot(.eveningReturn(store.currentPlanID ?? "debug"))
        case "progress":
            router.setRoot(.progress)
        case "journal":
            router.setRoot(.journal)
        case "settings":
            router.setRoot(.settings)
        case "coupleSetup":
            router.setRoot(.coupleSetup)
        case "coupleSpace":
            router.setRoot(.coupleSpace)
        case "paywall":
            router.setRoot(.paywall)
        default:
            router.setRoot(.home)
        }
    }
}
#endif
