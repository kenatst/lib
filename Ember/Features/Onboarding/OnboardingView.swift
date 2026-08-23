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
        VStack(alignment: .leading, spacing: 0) {
            // Progress as quiet ink marks, not bars.
            HStack(spacing: Spacing.xs) {
                ForEach(Array(questions.enumerated()), id: \.offset) { qIndex, _ in
                    Capsule()
                        .fill(qIndex < index ? Palette.rose : Palette.blush)
                        .frame(width: qIndex == index ? 22 : 12, height: 3)
                        .animation(Motion.gentle, value: index)
                }
                Spacer()
                Text(String.ember("questions.counter", index + 1, questions.count))
                    .emberCaption(Palette.softRose)
            }
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
        .padding(.horizontal, Spacing.md)
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
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text(String(localized: String.LocalizationValue(question.textKey)))
                .font(Typography.editorial(.title))
                .foregroundStyle(Palette.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.xl)

            VStack(spacing: Spacing.sm) {
                ForEach(Array(question.options.enumerated()), id: \.element.id) { optionIndex, option in
                    AnswerOption(
                        textKey: option.textKey,
                        delay: 0.06 * Double(optionIndex)
                    ) {
                        select(option)
                    }
                }
            }

            Spacer(minLength: 0)

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
            SketchMotifView(journey: intention, evolution: 0.2)
                .frame(width: 180, height: 210)
                .opacity(0.7)
            Spacer()

            EmberButton(title: String(localized: "profile.cta")) {
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
    let delay: TimeInterval
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .stroke(Palette.rose.opacity(0.75), lineWidth: 1.4)
                    .background(Circle().fill(Palette.cream))
                    .frame(width: 11, height: 11)
                Text(String(localized: String.LocalizationValue(textKey)))
                    .font(Typography.editorial(.body))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Palette.cream.opacity(0.85))
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
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
