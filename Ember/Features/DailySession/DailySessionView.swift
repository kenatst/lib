import SwiftUI

// MARK: - DailySessionView
//
// One day, three movements: Discover (an idea), Reflect (a prompt with a
// private note), Act (one real-world experiment). 3–7 minutes. Ends by
// inviting the evening Return.

struct DailySessionView: View {

    let dayNumber: Int

    @Environment(EmberStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: Step = .discover
    @State private var reflection = ""
    @State private var reflectionSaved = false

    nonisolated enum Step: Int, CaseIterable, Sendable {
        case discover = 0
        case reflect = 1
        case act = 2
    }

    private var day: JourneyDay? { JourneyCatalog.day(dayNumber) }
    private var intention: DesireIntention? { store.state.intention }

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
            if let day, let intention {
                content(for: day, intention: intention)
            } else {
                unavailableView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Step indicator — quiet ink ticks

    private var stepIndicator: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Step.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? Palette.rose : Palette.blush)
                    .frame(width: s == step ? 22 : 12, height: 3)
            }
            Spacer()
            Text("home.day.label \(dayNumber)")
                .emberCaption(Palette.softRose)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Content

    @ViewBuilder
    private func content(for day: JourneyDay, intention: DesireIntention) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch step {
                case .discover: discoverStep(day, intention: intention)
                case .reflect: reflectStep(day)
                case .act: actStep(day)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func discoverStep(_ day: JourneyDay, intention: DesireIntention) -> some View {
        SessionStepLayout(
            eyebrowKey: "session.step.discover.title",
            motif: {
                SketchMotifView(
                    journey: intention,
                    evolution: day.evolution,
                    strokeColor: Palette.intentionTint(intention),
                    lineWidth: 1.8
                )
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .opacity(0.85)
            }
        ) {
            Text(day.titleKey)
                .font(Typography.editorial(.title))
                .foregroundStyle(Palette.wine)
                .padding(.bottom, Spacing.md)

            Text(day.discoverKey)
                .emberProse(.title3)
        } cta: {
            nextButton("common.continue") {
                advance(to: .reflect)
            }
        }
    }

    private func reflectStep(_ day: JourneyDay) -> some View {
        SessionStepLayout(
            eyebrowKey: "session.step.reflect.title",
            motif: { EmptyView() }
        ) {
            EditorialQuote(text: String(localized: String.LocalizationValue(day.reflectKey)))
        } cta: {
            VStack(alignment: .leading, spacing: Spacing.md) {
                reflectionField

                if reflectionSaved {
                    Label {
                        Text("session.reflect.saved")
                            .emberCaption(Palette.mutedInk)
                    } icon: {
                        Image(systemName: "lock")
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

    private func actStep(_ day: JourneyDay) -> some View {
        SessionStepLayout(
            eyebrowKey: "session.step.act.title",
            motif: {
                SketchMotifView(
                    journey: store.state.intention ?? .myDesire,
                    evolution: min(1, day.evolution + 0.06),
                    strokeColor: Palette.intentionTint(store.state.intention ?? .myDesire),
                    lineWidth: 1.6
                )
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .opacity(0.6)
            }
        ) {
            Text(day.actKey)
                .emberProse(.title3)
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

            TextField(
                String(localized: "session.reflect.placeholder"),
                text: $reflection,
                axis: .vertical
            )
            .lineLimit(3...6)
            .font(Typography.editorial(.body))
            .foregroundStyle(Palette.ink)
            .scrollContentBackground(.hidden)
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Palette.cream.opacity(0.9))
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            )
            .autocorrectionDisabled(false)
        }
    }

    // MARK: Helpers

    private func nextButton(_ titleKey: String, _ action: @escaping () -> Void) -> some View {
        EmberButton(title: titleKey) {
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
        store.saveReflection(trimmed, day: dayNumber)
        Haptics.soft()
        withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion)) {
            reflectionSaved = true
        }
    }

    private func completeDay() {
        store.markDayComplete(dayNumber)
        Haptics.warm()
        router.replace(with: .eveningReturn(dayNumber))
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
            Text(eyebrowKey)
                .emberCaption(Palette.rose)
                .kerning(2.2)
                .textCase(.uppercase)
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

private func previewSessionStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.theirDesire)
    return store
}
