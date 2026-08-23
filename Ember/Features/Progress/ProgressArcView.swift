import SwiftUI

// MARK: - ProgressArcView
//
// Progress as an evolving sketch, not a scoreboard. The journey motif grows
// across three chapters; each completed day leaves a quiet ink tick.

struct ProgressArcView: View {

    @Environment(EmberStore.self) private var store

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

                Text("progress.days \(completed)")
                    .emberCaption(Palette.rose)
                    .kerning(1.6)
                    .textCase(.uppercase)
                    .padding(.top, Spacing.xs)

                // The evolving motif — the emotional progress bar.
                SketchMotifView(
                    journey: intention,
                    evolution: Double(completed) / Double(JourneyCatalog.totalDays),
                    strokeColor: Palette.intentionTint(intention),
                    lineWidth: 2.2
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
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Circle()
                .fill(completed >= week * 7 - (7 - min(week * 7, completed)) && completed >= min(week * 7, completed) ? Palette.wine : Palette.blush)
                .frame(width: 8, height: 8)
                .padding(.bottom, 2)

            Text("progress.chapter.\(week)")
                .emberProse(.callout, color: completed >= min(week * 7, JourneyCatalog.totalDays) ? Palette.ink : Palette.mutedInk)

            Spacer()
        }
    }

    // MARK: Day ticks — one small mark per day, filled when lived

    private var dayTicks: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(0..<3) { week in
                HStack(spacing: 10) {
                    ForEach(0..<7) { slot in
                        let dayNumber = week * 7 + slot + 1
                        let isDone = store.state.completedDays.contains(dayNumber)
                        Capsule()
                            .fill(isDone ? Palette.rose : Palette.blush.opacity(0.5))
                            .frame(width: isDone ? 18 : 10, height: 3)
                    }
                }
            }
        }
        .padding(.top, Spacing.xl)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("progress.days \(completed)"))
    }
}

#Preview {
    NavigationStack {
        ProgressArcView()
    }
    .environment(previewProgressStore())
}

private func previewProgressStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.myDesire)
    for day in [1, 2, 4, 5] { store.markDayComplete(day) }
    return store
}
