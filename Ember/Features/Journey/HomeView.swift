import SwiftUI

// MARK: - HomeView
//
// The living room of the app: today's day card with its motif, quiet access
// to progress, couple mode (Our Desire) and settings. No streaks, no badges.

struct HomeView: View {

    @Environment(EmberStore.self) private var store
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(StoreService.self) private var storeService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    private var intention: DesireIntention? { store.state.intention }

    // ONGOING DAILY GUIDE (Mission 004): Home answers "what does EMBER
    // suggest today?" — from the FROZEN daily plan, never a numbered course.
    private var todayPlan: DailyPlan? { store.planForToday() }

    private var todayTitle: String {
        guard let plan = todayPlan else { return String(localized: "home.title") }
        return String.ember(plan.titleContentID.localizationKey)
    }

    /// Session lived state for the motif drawing (0…1), capped — the sketch
    /// keeps evolving forever but the drawing API is bounded.
    private var evolutionForProgress: Double {
        let lived = Double(store.countCompletedSessions())
        // Slow the pace: each session adds a little; never "complete".
        return min(1, 0.08 + lived * 0.02)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if let intention {
                    dayCard(for: intention)
                } else {
                    emptyStateCard
                }
                footerLinks
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationBarHidden(true)
        .onAppear {
            guard !appeared else { return }
            withAnimation(Motion.resolved(Motion.breathe, reduceMotion: reduceMotion)) {
                appeared = true
            }
        }
    }

    // MARK: Pieces

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("home.wordmark")
                .font(Typography.editorial(.title3))
                .kerning(6)
                .foregroundStyle(Palette.wine)

            Spacer()

            Button {
                Haptics.selection()
                router.navigate(to: .settings)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(Palette.mutedInk)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("home.link.settings"))
        }
        .padding(.top, Spacing.md)
    }

    @ViewBuilder
    private func dayCard(for intention: DesireIntention) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SketchMotifView(
                journey: intention,
                evolution: evolutionForProgress,
                strokeColor: Palette.intentionTint(intention),
                lineWidth: 2.3
            )
            .frame(height: 240)
            .frame(maxWidth: .infinity)

            Group {
                // ONGOING: no numbered course label — today's theme title only.
                Text(todayTitle)
                    .font(Typography.editorial(.largeTitle))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, Spacing.lg)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // The four movements of a day, as one quiet line.
            Text(stepSummary)
                .emberProse(.footnote, color: Palette.mutedInk)
                .padding(.top, Spacing.sm)

            EmberButton(title: String(localized: "home.today.cta")) {
                beginDay()
            }
            .padding(.top, Spacing.lg)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(Palette.cream.opacity(0.75))
                .strokeBorder(Palette.hairline, lineWidth: 1)
        )
        .padding(.top, Spacing.lg)
    }

    private var stepSummary: String {
        String(localized: "home.step.discover") + " · "
            + String(localized: "home.step.reflect") + " · "
            + String(localized: "home.step.act") + " · "
            + String(localized: "home.step.return")
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("selection.title")
                .font(Typography.editorial(.title))
                .foregroundStyle(Palette.ink)
            Text("selection.subtitle")
                .emberProse(.callout, color: Palette.mutedInk)
            EmberButton(title: String(localized: "welcome.cta")) {
                router.navigate(to: .journeySelection)
            }
            .padding(.top, Spacing.sm)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(Palette.cream.opacity(0.75))
                .strokeBorder(Palette.hairline, lineWidth: 1)
        )
        .padding(.top, Spacing.lg)
    }

    private var footerLinks: some View {
        VStack(spacing: 0) {
            if intention == .ourDesire || store.state.coupleRole != nil {
                footerLink(icon: "figure.2.and.child.holdinghands", titleKey: "couple.setup.title") {
                    router.navigate(to: .coupleSetup)
                }
            }
            footerLink(icon: "text.book.closed", titleKey: "home.link.progress") {
                router.navigate(to: .progress)
            }
        }
        .padding(.top, Spacing.lg)
    }

    private func footerLink(icon: String, titleKey: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Palette.rose)
                Text(String.ember(titleKey))
                    .font(Typography.ui(.subheadline))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.softRose)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.hairline).frame(height: 1)
        }
    }

    // MARK: Actions

    private func beginDay() {
        Haptics.selection()
        // ONGOING ACCESS: gated by completed sessions, not day numbers.
        // The calendar can never refill the allowance.
        // Monotone counter: max of the persisted allowance usage and the
        // derived count — un-completing a movement can never re-open free.
        guard storeService.canStartDailySession(
            completedSessions: max(store.state.freeSessionsUsed,
                                   store.countCompletedSessions())) else {
            router.navigate(to: .paywall)
            return
        }
        // Freeze/open today's plan, then enter THIS session. Route identity =
        // frozen session ID; no derived day number can misroute the Return.
        guard let sessionID = store.currentPlanID else { return }
        let plan = store.planForToday()
        let actDone = store.state.sessionHistory.first {
            $0.id == plan?.id
        }?.completedMovements.contains(.act) ?? false
        if actDone {
            router.navigate(to: .eveningReturn(sessionID))
        } else {
            router.navigate(to: .dailySession(sessionID))
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(previewHomeStore())
    .environment(AppState(hasJourney: true))
    .environment(AppRouter())
    .environment(StoreService())
}

@MainActor
private func previewHomeStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.myDesire)
    return store
}
