import SwiftUI

// MARK: - EveningReturnView
//
// The soft landing. One honest question, four answers, no judgment.
// The response tunes later days via CheckInAdapter.

struct EveningReturnView: View {

    /// ONGOING IDENTITY: bound to ONE frozen session when routed by ID.
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

    @State private var response: CheckInResponse?
    @State private var saved = false
    @State private var appeared = false

    private var intention: DesireIntention? { store.state.intention }

    // CURRENT-DAY IMMUTABILITY (Mission 004): tonight's prompt comes from the
    // FROZEN plan. The session ID is captured when the view appears so a
    // return answered after midnight still lands on the right day.
    @State private var capturedSessionID: String?
    private var plan: DailyPlan? {
        if let sessionID, let bound = store.state.dailyPlans[sessionID] {
            return bound
        }
        if capturedSessionID == nil { _ = store.planForToday() }
        return store.state.dailyPlans[capturedSessionID ?? store.currentPlanID ?? ""]
    }

    private var returnPromptKey: String? {
        plan?.returnPromptID.localizationKey
    }

    var body: some View {
        ScrollView {
            Color.clear.frame(height: 0).onAppear {
                _ = store.planForToday()
                if capturedSessionID == nil { capturedSessionID = store.currentPlanID }
            }
            VStack(alignment: .leading, spacing: 0) {
                EditorialSketchView(
                    scene: saved ? .bloom : .moonThread,
                    color: saved ? Palette.rose : Palette.wine,
                    wash: saved ? Palette.blush : Palette.paper,
                    lineWidth: 1.45
                )
                .id(saved)
                .frame(height: 188)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .transition(.opacity)

                SectionEyebrow(key: "return.eyebrow")
                    .padding(.top, Spacing.sm)

                if let promptKey = returnPromptKey {
                    Text(String.ember(promptKey))
                        .font(Typography.editorial(.largeTitle))
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Spacing.sm)
                        .opacity(appeared ? 1 : 0)
                } else {
                    Text("return.title")
                        .font(Typography.editorial(.largeTitle))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, Spacing.sm)
                }

                Text("return.subtitle")
                    .emberProse(.callout, color: Palette.mutedInk)
                    .padding(.top, Spacing.sm)

                VStack(spacing: Spacing.sm) {
                    ForEach(CheckInResponse.allCases, id: \.rawValue) { candidate in
                        ReturnOption(
                            textKey: candidate.textKey,
                            isSelected: response == candidate,
                            delay: 0.08 * Double(CheckInResponse.allCases.firstIndex(of: candidate) ?? 0)
                        ) {
                            choose(candidate)
                        }
                    }
                }
                .padding(.top, Spacing.xl)

                if saved {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Label {
                            // Truthful confirmation: never claim a durable
                            // save while persistence is volatile.
                            Text(store.persistenceStatus == .ready
                                 ? "return.saved"
                                 : "return.held")
                                .emberProse(.callout, color: Palette.wine)
                        } icon: {
                            Image(systemName: store.persistenceStatus == .ready
                                  ? "moon.stars" : "hourglass")
                                .foregroundStyle(Palette.rose)
                        }
                        .transition(.opacity)

                        EmberButton(title: String(localized: "return.close.day")) {
                            closeDay()
                        }
                    }
                    .padding(.top, Spacing.xl)
                }

                Spacer(minLength: Spacing.xxl)
            }
            .padding(.horizontal, Spacing.md)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PaperBackground(tint: Palette.paper))
        .navigationBarBackButtonHidden(saved)
        .onAppear {
            guard !appeared else { return }
            withAnimation(Motion.resolved(Motion.ink, reduceMotion: reduceMotion)) {
                appeared = true
            }
        }
    }

    private func choose(_ candidate: CheckInResponse) {
        Haptics.selection()
        withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion)) {
            response = candidate
        }
        // Save immediately — one tap is enough; no "submit" ceremony.
        // This response updates HISTORY + learned signals against the CAPTURED
        // session; the frozen plan on screen is untouched. Only TOMORROW bends.
        let targetSession = self.sessionID ?? capturedSessionID ?? store.currentPlanID ?? ""
        store.recordCheckIn(
            CheckIn(dayNumber: dayNumber, response: candidate, date: .now),
            forSession: targetSession
        )
        if capturedSessionID == nil { capturedSessionID = targetSession }
        withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion, delay: 0.2)) {
            saved = true
        }
    }

    private func closeDay() {
        Haptics.soft()
        router.popToRoot()
    }
}

// MARK: - One return option

private struct ReturnOption: View {

    let textKey: String
    let isSelected: Bool
    let delay: TimeInterval
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        QuietOption(textKey: textKey, isSelected: isSelected, action: action)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 14)
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
        EveningReturnView(dayNumber: 3)
    }
    .environment(previewReturnStore())
    .environment(AppRouter())
}

@MainActor
private func previewReturnStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.ourDesire)
    store.markDayComplete(3)
    return store
}
