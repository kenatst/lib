import SwiftUI

// MARK: - DailySessionView
//
// One day, three movements: Discover (an idea), Reflect (a prompt with a
// private note), Act (one real-world experiment). 3–7 minutes. Ends by
// inviting the evening Return.

struct DailySessionView: View {

    /// ONGOING IDENTITY: this view is bound to ONE frozen session.
    private let sessionID: String?
    /// Legacy numbered entry point (migration-era routes only).
    private let dayNumber: Int

    init(sessionID: String) {
        self.sessionID = sessionID
        self.dayNumber = 0
    }

    init(dayNumber: Int) {
        self.sessionID = nil
        self.dayNumber = dayNumber
    }

    @Environment(EmberStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: Step = .discover
    @State private var reflection = ""
    @State private var reflectionSaved = false
    /// Debounces draft autosave: one write per pause, not per keystroke.
    @State private var draftSaveTask: Task<Void, Never>?

    private func restoreDraftIfNeeded() {
        if reflection.isEmpty {
            if let sid = resolvedSessionID, let draft = store.sessionDraft(for: sid) {
                reflection = draft
            } else if sessionID == nil, let legacy = store.draft(for: dayNumber) {
                reflection = legacy
            }
        }
    }

    nonisolated enum Step: Int, CaseIterable, Sendable {
        case discover = 0
        case reflect = 1
        case act = 2
    }

    // TODAY IS SNAPSHOTTED (Mission 004): everything on screen resolves from
    // the FROZEN DailyPlan — never recomputed from mutable state. Tonight's
    // check-in cannot retroactively change what today shows. When routed by
    // session ID, THIS exact session renders even if the calendar has rolled.
    private var resolvedSessionID: String? { sessionID ?? store.currentPlanID }
    private var plan: DailyPlan? {
        if let sessionID, let bound = store.state.dailyPlans[sessionID] {
            return bound
        }
        return store.planForToday()
    }
    private var intention: DesireIntention? { store.state.intention }

    private var day: JourneyDay? {
        guard let plan else { return nil }
        // Motif evolution still needs a 0…1 position for the sketch; derive it
        // from session history count (ongoing), capped for the drawing API.
        let lived = store.countCompletedSessions()
        let evolutionSlot = (lived % 21)
        return JourneyDay(number: max(1, evolutionSlot), week: min(3, evolutionSlot / 7 + 1), theme: plan.theme)
    }

    /// True when the frozen plan emphasizes its own theme — deeper variant.
    private var isThemeEmphasized: Bool {
        guard let plan else { return false }
        return plan.emphasizedThemes.contains(plan.theme)
    }

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
            if let day, let plan, let intention {
                content(for: day, plan: plan, intention: intention)
            } else {
                unavailableView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Step indicator — quiet ink ticks

    private var stepIndicator: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                SectionEyebrow(key: "daily.guide.eyebrow")
                Spacer()
                Text(resolvedSessionID.flatMap { store.state.dailyPlans[$0].map { EmberDateFormatting.display($0.day) } }
                     ?? String.ember("home.day.label", dayNumber))
                    .emberCaption(Palette.softRose)
            }

            DailyStepIndicator(
                steps: [
                    "daily.movement.discover",
                    "daily.movement.reflect",
                    "daily.movement.act"
                ],
                currentIndex: step.rawValue
            )
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xs)
    }

    // MARK: Content

    @ViewBuilder
    private func content(for day: JourneyDay, plan: DailyPlan, intention: DesireIntention) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch step {
                case .discover: discoverStep(day, plan: plan, intention: intention)
                case .reflect: reflectStep(day, plan: plan)
                case .act: actStep(day, plan: plan)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func discoverStep(_ day: JourneyDay, plan: DailyPlan, intention: DesireIntention) -> some View {
        SessionStepLayout(
            eyebrowKey: "session.step.discover.title",
            motif: {
                ZStack {
                    InkWashShape()
                        .fill(Palette.blush.opacity(0.38))
                    SketchMotifView(
                        journey: intention,
                        evolution: day.evolution,
                        strokeColor: Palette.intentionTint(intention),
                        lineWidth: 2.1
                    )
                    .padding(Spacing.sm)
                }
                .frame(height: 210)
                .frame(maxWidth: .infinity)
            }
        ) {
            // FROZEN PLAN CONTENT: resolved from the plan's stable IDs.
            Text(String.ember(plan.titleContentID.localizationKey))
                .font(Typography.editorial(.title))
                .foregroundStyle(Palette.wine)
                .padding(.bottom, Spacing.md)

            Text(String.ember(plan.discoverContentID.localizationKey))
                .emberProse(.title3)
        } cta: {
            nextButton("common.continue") {
                advance(to: .reflect)
            }
        }
    }

    private func reflectStep(_ day: JourneyDay, plan: DailyPlan) -> some View {
        SessionStepLayout(
            eyebrowKey: "session.step.reflect.title",
            motif: { EmptyView() }
        ) {
            EditorialQuote(text: String.ember(plan.reflectContentID.localizationKey))
        } cta: {
            VStack(alignment: .leading, spacing: Spacing.md) {
                reflectionField
                    .onAppear { restoreDraftIfNeeded() }
                    .onChange(of: reflection) { _, newText in
                        // Autosave the draft as they type — debounced so a
                        // pause in writing triggers one write, not every key.
                        draftSaveTask?.cancel()
                        draftSaveTask = Task {
                            try? await Task.sleep(for: .seconds(1.2))
                            guard !Task.isCancelled else { return }
                            if let sid = resolvedSessionID {
                                store.saveSessionDraft(newText, sessionID: sid)
                            } else {
                                store.saveDraft(newText, day: dayNumber)
                            }
                        }
                    }

                if reflectionSaved {
                    Label {
                        // Truthful confirmation: only claim durable save when
                        // the write actually reached storage.
                        Text(store.persistenceStatus == .ready
                             ? "session.reflect.saved"
                             : "session.reflect.held")
                            .emberCaption(Palette.mutedInk)
                    } icon: {
                        Image(systemName: store.persistenceStatus == .ready ? "lock" : "hourglass")
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.rose)
                    }
                    .transition(.opacity)
                }

                nextButton("common.continue") {
                    saveReflectionIfNeeded()
                    advance(to: .act)
                }
            }
        }
    }

    private func actStep(_ day: JourneyDay, plan: DailyPlan) -> some View {
        SessionStepLayout(
            eyebrowKey: "session.step.act.title",
            motif: {
                EditorialSketchView(
                    scene: .threshold,
                    color: Palette.intentionTint(store.state.intention ?? .myDesire),
                    wash: Palette.paper,
                    lineWidth: 1.3
                )
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            }
        ) {
            if store.state.intention == .ourDesire,
               let space = store.state.coupleRole.map({ $0 == .partnerOne ? CoupleSpace.partnerOne : .partnerTwo }),
               let assignment = plan.coupleAssignmentIDs?[space] {
                // OUR DESIRE: the frozen plan's asymmetric assignment for THIS role.
                Text(String.ember(assignment.localizationKey))
                    .emberProse(.title3)
            } else if store.state.intention == .ourDesire {
                // Legacy fallback: the authored per-day pair (migration era).
                Text(String.ember("couple.asymmetric.day.\(dayNumber).\(store.state.coupleRole?.rawValue ?? "partnerOne")"))
                    .emberProse(.title3)
            } else {
                Text(String.ember(plan.actContentID.localizationKey))
                    .emberProse(.title3)
            }
        } cta: {
            VStack(spacing: Spacing.md) {
                EmberButton(title: String(localized: "session.finish")) {
                    completeDay()
                }
                Text("session.finish.evening.teaser")
                    .emberCaption()
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: Reflection field

    private var reflectionField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("session.reflect.prompt")
                .emberCaption()

            PaperField(placeholderKey: "session.reflect.placeholder", text: $reflection)

            Label {
                Text("session.reflect.privacy")
                    .emberCaption(Palette.mutedInk)
            } icon: {
                Image(systemName: "lock")
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(Palette.rose)
            }
            .padding(.top, 4)
        }
    }

    // MARK: Helpers

    private func nextButton(_ titleKey: String, _ action: @escaping () -> Void) -> some View {
        EmberButton(title: String.ember(titleKey)) {
            Haptics.selection()
            action()
        }
        .padding(.top, Spacing.lg)
    }

    private func advance(to newStep: Step) {
        withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion)) {
            step = newStep
        }
    }

    private func saveReflectionIfNeeded() {
        let trimmed = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // ONGOING ENGINE: reflections attach to THIS frozen session ID.
        if let sid = resolvedSessionID {
            store.saveSessionReflection(trimmed, sessionID: sid)
            store.saveSessionDraft("", sessionID: sid)
        } else {
            store.saveReflection(trimmed, day: dayNumber)
            store.clearDraft(day: dayNumber)
        }
        Haptics.soft()
        withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion)) {
            reflectionSaved = true
        }
    }

    private func completeDay() {
        saveReflectionIfNeeded()
        // ONGOING ENGINE: record movements + completion; no numbered course.
        store.markMovement(.discover)
        store.markMovement(.act)
        store.completeTodaySession()
        Haptics.warm()
        // Route identity = THIS frozen session, whatever the clock says next.
        if let sessionID = resolvedSessionID {
            router.replace(with: .eveningReturn(sessionID))
        } else {
            router.replace(with: .eveningReturnLegacy(dayNumber))
        }
    }

    private var unavailableView: some View {
        VStack(spacing: Spacing.md) {
            Text("progress.empty").emberProse()
            EmberButton(title: String(localized: "home.wordmark")) {
                router.popToRoot()
            }
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Router helper: swap the top of the stack without pushing deeper

extension AppRouter {
    /// Replaces the topmost route (used when a day session flows into its
    /// evening return — no back-trail into the finished session).
    func replace(with route: AppRoute) {
        if path.isEmpty {
            path = [route]
        } else {
            path[path.count - 1] = route
        }
    }
}

// MARK: - Shared step scaffold

private struct SessionStepLayout<Motif: View, Content: View, CTA: View>: View {

    let eyebrowKey: String
    let motif: Motif
    let content: Content
    let cta: CTA

    init(
        eyebrowKey: String,
        @ViewBuilder motif: () -> Motif,
        @ViewBuilder content: () -> Content,
        @ViewBuilder cta: () -> CTA
    ) {
        self.eyebrowKey = eyebrowKey
        self.motif = motif()
        self.content = content()
        self.cta = cta()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionEyebrow(key: eyebrowKey)
                .padding(.top, Spacing.lg)

            motif
                .padding(.vertical, Spacing.md)

            content.padding(.top, Spacing.md)

            Spacer(minLength: Spacing.xl)

            cta
        }
    }
}

#Preview("Day 4") {
    NavigationStack {
        DailySessionView(dayNumber: 4)
    }
    .environment(previewSessionStore())
    .environment(AppRouter())
}

@MainActor
private func previewSessionStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.theirDesire)
    return store
}
