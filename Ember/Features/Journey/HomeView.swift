import SwiftUI

// MARK: - HomeView
//
// The living room of the app: today's day card with its motif, quiet access
// to progress, couple mode (Our Desire) and settings. No streaks, no badges.

struct HomeView: View {

    @Environment(EmberStore.self) private var store
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    private var intention: DesireIntention? { store.state.intention }
    private var nextDay: Int { appState.suggestedDayNumber(completedDays: store.state.completedDays) }
    private var isJourneyComplete: Bool {
        store.state.completedDays.count >= JourneyCatalog.totalDays
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
                lineWidth: 2.0
            )
            .frame(height: 240)
            .frame(maxWidth: .infinity)

            Group {
                if isJourneyComplete {
                    Text("progress.title")
                        .font(Typography.editorial(.title))
                        .foregroundStyle(Palette.ink)
                } else {
                    Text("home.day.label \(nextDay)")
                        .emberCaption(Palette.rose)
                        .kerning(1.8)
                        .textCase(.uppercase)

                    Text(JourneyCatalog.day(nextDay)?.titleKey ?? "home.title")
                        .font(Typography.editorial(.largeTitle))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, Spacing.xs)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, Spacing.lg)

            if isJourneyComplete {
                Text("home.complete.today")
                    .emberProse(.callout, color: Palette.mutedInk)
                    .padding(.top, Spacing.sm)
            } else {
                // The four movements of a day, as one quiet line.
                Text(stepSummary)
                    .emberProse(.footnote, color: Palette.mutedInk)
                    .padding(.top, Spacing.sm)
            }

            EmberButton(
                title: isJourneyComplete
                    ? String(localized: "progress.title")
                    : (store.state.completedDays.contains(nextDay)
                        ? String(localized: "home.resume \(nextDay)")
                        : String(localized: "home.begin \(nextDay)"))
            ) {
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

    private var evolutionForProgress: Double {
        let completed = Double(store.state.completedDays.count)
        let base = completed / Double(JourneyCatalog.totalDays)
        // Nudge slightly ahead so the motif always feels alive on the active day.
        return min(1, base + 0.05)
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
                Text(titleKey)
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
        if isJourneyComplete {
            router.navigate(to: .progress)
        } else if store.state.completedDays.contains(nextDay) {
            router.navigate(to: .eveningReturn(nextDay))
        } else {
            router.navigate(to: .day(nextDay))
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
}

private func previewHomeStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.myDesire)
    return store
}
