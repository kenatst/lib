import SwiftUI

// MARK: - DesireProfileView
//
// The qualitative portrait. Ordered paragraphs, serif voice, the motif
// evolving behind — no numbers, no radar charts, no percentages.

struct DesireProfileView: View {

    @Environment(EmberStore.self) private var store
    @Environment(AppRouter.self) private var router

    @State private var appeared = false

    private var profile: DesireProfile? { store.state.profile }

    var body: some View {
        ScrollView {
            if let profile {
                content(for: profile)
            } else {
                // Defensive: profile is always set before this screen in flow.
                VStack(spacing: Spacing.md) {
                    Text("profile.title").emberTitle()
                    Text("profile.footer").emberProse(.callout, color: Palette.mutedInk)
                }
                .padding(Spacing.xl)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PaperBackground(tint: Palette.paper))
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private func content(for profile: DesireProfile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SketchMotifView(journey: profile.intention, evolution: 0.3)
                .frame(width: 170, height: 190)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.lg)
                .opacity(appeared ? 0.9 : 0)

            Text("profile.title")
                .font(Typography.editorial(.largeTitle))
                .foregroundStyle(Palette.ink)
                .padding(.top, Spacing.lg)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            Text(String.ember("profile.lede.\(profile.intention.rawValue)"))
                .emberProse(.callout, color: Palette.mutedInk)
                .padding(.top, Spacing.sm)

            Text("profile.standout")
                .emberCaption(Palette.rose)
                .kerning(1.6)
                .textCase(.uppercase)
                .padding(.top, Spacing.xl)

            ForEach(Array(profile.readings.enumerated()), id: \.element.dimension) { index, reading in
                DimensionParagraph(reading: reading, delay: 0.2 + Double(index) * 0.12)
                    .padding(.top, Spacing.lg)
            }

            Text("profile.footer")
                .emberCaption()
                .italic()
                .padding(.top, Spacing.xl)

            EmberButton(title: String(localized: "profile.cta")) {
                Haptics.warm()
                router.setRoot(.home)
            }
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, Spacing.md)
        .onAppear {
            guard !appeared else { return }
            withAnimation(Motion.resolved(Motion.ink, reduceMotion: reduceMotion)) {
                appeared = true
            }
        }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
}

// MARK: - One dimension paragraph

private struct DimensionParagraph: View {

    let reading: DimensionReading
    let delay: TimeInterval

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var textKey: String {
        switch reading.band {
        case .guarded: reading.dimension.openingKey
        case .middle: reading.dimension.middleKey
        case .rich: reading.dimension.richKey
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Quiet margin mark: a hand-drawn tick whose weight hints at strength.
            Path { path in
                path.move(to: CGPoint(x: 1, y: 4))
                path.addLine(to: CGPoint(x: 2.5, y: 16))
            }
            .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            .frame(width: 6, height: 20)

            Text(String(localized: String.LocalizationValue(textKey)))
                .emberProse()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .onAppear {
            guard !appeared else { return }
            withAnimation(Motion.resolved(Motion.ink, reduceMotion: reduceMotion, delay: delay)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var strokeColor: Color {
        switch reading.band {
        case .rich: Palette.wine
        case .middle: Palette.rose
        case .guarded: Palette.softRose
        }
    }

    private var strokeWidth: CGFloat {
        switch reading.band {
        case .rich: 3
        case .middle: 2.2
        case .guarded: 1.5
        }
    }
}

#Preview {
    NavigationStack {
        DesireProfileView()
    }
    .environment(previewStore())
    .environment(AppRouter())
}

private func previewStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.myDesire)
    var responses = Onboarding.Responses()
    responses.record(.init(questionID: .duration, optionID: .months))
    responses.record(.init(questionID: .stress, optionID: .stressSome))
    responses.record(.init(questionID: .myState, optionID: .longingWithoutShape))
    responses.record(.init(questionID: .mySelfConnection, optionID: .atEasePassing))
    responses.record(.init(questionID: .myPressure, optionID: .pressureHope))
    store.recordResponses(responses)
    store.setProfile(DesireProfileDeriver.derive(from: responses, intention: .myDesire))
    return store
}
