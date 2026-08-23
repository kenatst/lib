import SwiftUI

// MARK: - JournalView
//
// Your own words, back to you. Lists every saved reflection with its day.
// Private by definition — this view is the only reader of reflections.

struct JournalView: View {

    @Environment(EmberStore.self) private var store

    /// Current space's reflections, newest first. Never shows a partner's.
    private var entries: [(day: Int, text: String)] {
        store.journalEntries
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if entries.isEmpty {
                    Text("journal.empty")
                        .emberProse(.callout, color: Palette.mutedInk)
                        .italic()
                        .padding(.top, Spacing.xl)
                } else {
                    ForEach(entries, id: \.day) { entry in
                        journalRow(entry)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(Text("journal.title"))
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func journalRow(_ entry: (day: Int, text: String)) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String.ember("journal.day.label", entry.day))
                .emberCaption(Palette.rose)
                .kerning(1.6)
                .textCase(.uppercase)

            if let day = JourneyCatalog.day(entry.day),
               let theme = decodeTheme(day.theme) {
                Text(String.ember(day.titleKey))
                    .emberCaption(Palette.mutedInk.opacity(0.75))
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

    private func decodeTheme(_ theme: DayTheme) -> DayTheme? { theme }
}

#Preview {
    NavigationStack {
        JournalView()
    }
    .environment(previewJournalStore())
}

private func previewJournalStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.myDesire)
    store.markDayComplete(1)
    store.markDayComplete(4)
    store.saveReflection("The quiet was easier tonight.", day: 1)
    store.saveReflection("I noticed the light on the wall and stayed.", day: 4)
    return store
}
