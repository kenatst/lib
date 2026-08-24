import SwiftUI

// MARK: - OnboardingView
//
// Adaptive, emotionally intelligent intake. One question at a time; the
// question set branches by journey. Answers feed the Desire Profile. Feels
// like a conversation with a thoughtful friend — never a form.

struct OnboardingView: View {

    let intention: DesireIntention

    @Environment(EmberStore.self) private var store
    @Environment(AppRouter.self) private var router

    @State private var responses = Onboarding.Responses()
    @State private var index = 0
    @State private var directionForward = true

    private let questions: [Onboarding.Question]

    init(intention: DesireIntention) {
        self.intention = intention
        self.questions = Onboarding.questions(for: intention)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(Array(questions.enumerated()), id: \.offset) { qIndex, _ in
                            Capsule()
                                .fill(qIndex <= index ? Palette.rose : Palette.blush)
                                .frame(width: qIndex == index ? 22 : 12, height: 3)
                        }
                        Spacer()
                        Text(String.ember("questions.counter", min(index + 1, questions.count), questions.count))
                            .emberCaption(Palette.softRose)
                    }
                    .animation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion), value: index)
                    .padding(.top, Spacing.md)

                    if index < questions.count {
                        questionView(questions[index])
                            .id(index)
                            .transition(directionForward
                                ? .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                              removal: .move(edge: .leading).combined(with: .opacity))
                                : .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                              removal: .move(edge: .trailing).combined(with: .opacity)))
                    } else {
                        completingView
                    }
                }
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, Spacing.md)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .navigationBarBackButtonHidden(index > 0 && index < questions.count)
        .toolbar {
            if index < questions.count {
                ToolbarItem(placement: .topBarLeading) {
                    if index > 0 {
                        Button(String(localized: "common.back")) {
                            goBack()
                        }
                        .font(Typography.ui(.subheadline))
                    }
                }
            }
        }
    }

    // MARK: Question

    @ViewBuilder
    private func questionView(_ question: Onboarding.Question) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                SectionEyebrow(key: "questions.private")
                    .padding(.top, Spacing.md)
                Spacer()
                EditorialSketchView(
                    scene: contextualScene(for: question.id),
                    color: Palette.intentionTint(intention),
                    wash: Palette.paper,
                    lineWidth: 1.25
                )
                .frame(width: 116, height: 96)
            }
            .padding(.top, Spacing.sm)

            Text(String(localized: String.LocalizationValue(question.textKey)))
                .font(Typography.editorial(.largeTitle))
                .foregroundStyle(Palette.ink)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.md)

            VStack(spacing: 0) {
                ForEach(Array(question.options.enumerated()), id: \.element.id) { optionIndex, option in
                    AnswerOption(
                        textKey: option.textKey,
                        mark: "—",
                        delay: 0.06 * Double(optionIndex)
                    ) {
                        select(option)
                    }
                }
            }
            .padding(.top, Spacing.xl)

            Spacer(minLength: Spacing.xl)

            Text("questions.skipnote")
                .emberCaption(Palette.mutedInk.opacity(0.8))
                .padding(.bottom, Spacing.lg)
        }
    }

    // MARK: Completion → profile derivation

    @ViewBuilder
    private var completingView: some View {
        VStack(spacing: 0) {
            Spacer()
            EditorialSketchView(
                scene: .bloom,
                color: Palette.intentionTint(intention),
                wash: Palette.paper
            )
            .frame(width: 220, height: 230)
            Spacer()

            EmberButton(title: String(localized: "questions.reveal.cta")) {
                finish()
            }
            .padding(.bottom, Spacing.lg)

            Text("questions.heading")
                .emberCaption()
                .multilineTextAlignment(.center)
                .padding(.bottom, Spacing.md)
        }
    }

    // MARK: Actions

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func contextualScene(for question: Onboarding.QuestionID) -> EditorialSketchScene {
        switch question {
        case .duration: .threshold
        case .stress: .ribbon
        case .myState, .mySelfConnection, .myPressure: .handOnHeart
        case .theirConnection, .theirVoice, .theirSeen: .profiles
        case .ourRhythm, .ourTouch, .ourCuriosity: .almostTouching
        }
    }

    private func select(_ option: Onboarding.Question.Option) {
        guard index < questions.count else { return }
        let question = questions[index]
        Haptics.selection()
        withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion)) {
            directionForward = true
            responses.record(.init(questionID: question.id, optionID: option.id))
            index += 1
        }
    }

    private func goBack() {
        guard index > 0 else { return }
        withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion)) {
            directionForward = false
            index -= 1
        }
    }

    private func finish() {
        store.setIntention(intention)
        store.recordResponses(responses)
        let profile = DesireProfileDeriver.derive(from: responses, intention: intention)
        store.setProfile(profile)
        Haptics.warm()
        router.navigate(to: .desireProfile)
    }
}

// MARK: - One answer row (editorial line, not a checkbox)

private struct AnswerOption: View {

    let textKey: String
    let mark: String
    let delay: TimeInterval
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        QuietOption(textKey: textKey, mark: mark, action: action)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 18)
        .onAppear {
            guard !appeared else { return }
            withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion, delay: delay)) {
                appeared = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingView(intention: .myDesire)
    }
    .environment(EmberStore())
    .environment(AppRouter())
}
