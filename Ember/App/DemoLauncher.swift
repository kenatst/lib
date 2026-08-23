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

        // Mark days complete (and give a couple of them reflections).
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
        if value("-ember-checkin") != nil {
            let day = max(1, store.state.completedDays.count)
            store.recordCheckIn(CheckIn(dayNumber: day, response: .feltDifferent, date: .now))
        }

        if let handedOff = value("-ember-handoff") {
            let role: EmberStore.CoupleRole = (value("-ember-role") == "two") ? .partnerTwo : .partnerOne
            store.handOffNote(handedOff, from: role.other)
        }

        // Open a specific scene.
        if let route = value("-ember-route") {
            appState.activate()
            switch route {
            case "welcome":
                break
            case "selection":
                router.setRoot(.journeySelection)
            case "onboarding":
                let intention = DesireIntention(rawValue: value("-ember-intention") ?? "") ?? .myDesire
                router.setRoot(.onboarding(intention))
            case "profile":
                router.setRoot(.desireProfile)
            case "day":
                let day = Int(value("-ember-day") ?? "") ?? (store.state.completedDays.max() ?? 0) + 1
                router.setRoot(.day(min(day, JourneyCatalog.totalDays)))
            case "return":
                let day = Int(value("-ember-day") ?? "") ?? max(1, store.state.completedDays.count)
                router.setRoot(.eveningReturn(min(day, JourneyCatalog.totalDays)))
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
            default:
                router.setRoot(.home)
            }
        }
    }
}
#endif
