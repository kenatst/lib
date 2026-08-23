import SwiftUI

// MARK: - ProgressArcView
//
// Progress as an evolving sketch, not a scoreboard. The journey motif grows
// across three chapters; each completed day leaves a quiet ink tick.

struct ProgressArcView: View {

    @Environment(EmberStore.self) private var store
    @Environment(AppRouter.self) private var router

    private var intention: DesireIntention {
        store.state.intention ?? .myDesire
    }

    private var completed: Int { store.state.completedDays.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("progress.title")
                    .font(Typography.editorial(.largeTitle))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, Spacing.lg)

                Text(String.ember("progress.days", completed))
                    .emberCaption(Palette.rose)
                    .kerning(1.6)
                    .textCase(.uppercase)
                    .padding(.top, Spacing.xs)

                // The evolving motif — the emotional progress bar.
                SketchMotifView(
                    journey: intention,
                    evolution: Double(completed) / Double(JourneyCatalog.totalDays),
                    strokeColor: Palette.intentionTint(intention),
                    lineWidth: 2.5
                )
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)

                chapters

                if completed == 0 {
                    Text("progress.empty")
                        .emberProse(.callout, color: Palette.mutedInk)
                        .italic()
                        .padding(.top, Spacing.md)
                }

                dayTicks

                if !store.journalEntries.isEmpty {
                    Button {
                        Haptics.selection()
                        router.navigate(to: .journal)
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "book")
                                .font(.system(size: 15, weight: .light))
                                .foregroundStyle(Palette.rose)
                            Text(String.ember("journal.link"))
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
                    .accessibilityAddTraits(.isButton)
                    .overlay(alignment: .top) {
                        Rectangle().fill(Palette.hairline).frame(height: 1)
                    }
                    .padding(.top, Spacing.lg)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PaperBackground(tint: Palette.paper))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Chapters

    private var chapters: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            chapterRow(1)
            chapterRow(2)
            chapterRow(3)
        }
        .padding(.top, Spacing.md)
    }

    private func chapterRow(_ week: Int) -> some View {
        let daysInWeek = min(week * 7, JourneyCatalog.totalDays) - (week - 1) * 7
        let chapterComplete = completed >= (week - 1) * 7 + daysInWeek
        let chapterStarted = completed > (week - 1) * 7

        return HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Circle()
                .fill(chapterComplete ? Palette.wine : (chapterStarted ? Palette.rose : Palette.blush))
                .frame(width: 8, height: 8)
                .padding(.bottom, 2)

            Text(String.ember("progress.chapter.\(week)"))
                .emberProse(.callout, color: chapterStarted ? Palette.ink : Palette.mutedInk)

            Spacer()
        }
    }

    // MARK: Day ticks — one small mark per day, filled when lived.
    // Aligned with chapter rows so the grid reads as one system.

    private var dayTicks: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(0..<3) { week in
                HStack(spacing: 12) {
                    ForEach(0..<7) { slot in
                        let dayNumber = week * 7 + slot + 1
                        let isDone = store.state.completedDays.contains(dayNumber)
                        Circle()
                            .fill(isDone ? Palette.wine : Palette.blush)
                            .frame(width: isDone ? 7 : 5, height: isDone ? 7 : 5)
                    }
                }
                .padding(.leading, 16)   // aligns under chapter text
            }
        }
        .padding(.top, Spacing.lg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String.ember("progress.days", completed)))
    }
}

#Preview {
    NavigationStack {
        ProgressArcView()
    }
    .environment(previewProgressStore())
}

@MainActor
private func previewProgressStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.myDesire)
    for day in [1, 2, 4, 5] { store.markDayComplete(day) }
    return store
}
