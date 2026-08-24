import SwiftUI

// MARK: - JournalView
//
// Your own words, back to you. Ongoing sessions show their calendar date;
// legacy day-numbered entries keep their original labels. Private by
// definition — this view is the only reader of reflections.

struct JournalView: View {

    @Environment(EmberStore.self) private var store

    /// Current space's reflections, newest first. Never shows a partner's.
    private var entries: [EmberStore.JournalEntry] {
        store.allJournalEntries
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        SectionEyebrow(key: "journal.eyebrow")
                        Text("journal.title")
                            .font(Typography.editorial(.largeTitle))
                            .foregroundStyle(Palette.ink)
                        Label {
                            Text("journal.private")
                                .emberCaption(Palette.mutedInk)
                        } icon: {
                            Image(systemName: "lock")
                                .font(.system(size: 10, weight: .light))
                                .foregroundStyle(Palette.rose)
                        }
                    }

                    Spacer(minLength: 0)

                    EditorialSketchView(
                        scene: .ribbon,
                        wash: Palette.paper,
                        lineWidth: 1.15
                    )
                    .frame(width: 108, height: 100)
                }
                .padding(.top, Spacing.lg)

                EditorialDivider()
                    .frame(width: 54)
                    .padding(.top, Spacing.md)

                if entries.isEmpty {
                    Text("journal.empty")
                        .emberProse(.callout, color: Palette.mutedInk)
                        .italic()
                        .padding(.top, Spacing.xl)
                } else {
                    ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                        journalRow(entry)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func journalRow(_ entry: EmberStore.JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let legacyDay = entry.legacyDayNumber {
                // Legacy entry: keep the original day-number label.
                Text(String.ember("journal.day.label", legacyDay))
                    .emberCaption(Palette.rose)
                    .kerning(1.6)
                    .textCase(.uppercase)

                if let intention = store.state.intention,
                   let day = JourneyCatalog.day(legacyDay, for: intention) {
                    Text(String.ember(day.titleKey(offset: intention.poolOffset)))
                        .emberCaption(Palette.mutedInk.opacity(0.75))
                }
            } else if let dateLabel = entry.dateLabel {
                // Ongoing entry: quiet calendar date, no course numbering.
                Text(dateLabel)
                    .emberCaption(Palette.rose)
                    .kerning(1.6)

                if let sessionID = entry.sessionID,
                   let theme = store.state.dailyPlans[sessionID]?.theme {
                    Text(String.ember("journal.theme.\(theme.rawValue)"))
                        .emberCaption(Palette.mutedInk.opacity(0.78))
                }
            }

            Text(entry.text)
                .emberProse(.callout)
                .padding(.top, 2)

            Path { path in
                path.move(to: CGPoint(x: 0, y: 4))
                path.addLine(to: CGPoint(x: 34, y: 4))
            }
            .stroke(Palette.softRose, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            .padding(.top, Spacing.sm)
        }
        .padding(.top, Spacing.lg)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        JournalView()
    }
    .environment(previewJournalStore())
}

@MainActor
private func previewJournalStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.myDesire)
    _ = store.planForToday()
    store.saveSessionReflection("The quiet was easier tonight.", sessionID: store.currentPlanID ?? "")
    return store
}
