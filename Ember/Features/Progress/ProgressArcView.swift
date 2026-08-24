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

    /// Sessions ever lived — ongoing measure (legacy days migrate in).
    private var completed: Int { store.state.sessionHistory.count }

    private var exploredThemes: [DayTheme] {
        var seen = Set<DayTheme>()
        return store.state.sessionHistory.compactMap { record in
            seen.insert(record.theme).inserted ? record.theme : nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SectionEyebrow(key: "progress.eyebrow")
                    .padding(.top, Spacing.lg)

                Text("progress.title")
                    .font(Typography.editorial(.largeTitle))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, Spacing.xs)

                Text(String.ember("progress.days", completed))
                    .emberProse(.callout, color: Palette.mutedInk)
                    .padding(.top, Spacing.sm)

                ZStack {
                    InkWashShape().fill(Palette.blush.opacity(0.38))
                    SketchMotifView(
                        journey: intention,
                        evolution: min(1, 0.08 + Double(completed) * 0.02),
                        strokeColor: Palette.intentionTint(intention),
                        lineWidth: 2.5
                    )
                    .padding(Spacing.md)
                }
                .frame(height: 310)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)

                if completed == 0 {
                    Text("progress.empty")
                        .emberProse(.callout, color: Palette.mutedInk)
                        .italic()
                        .padding(.top, Spacing.md)
                }

                if !exploredThemes.isEmpty {
                    SectionEyebrow(key: "progress.themes")
                        .padding(.top, Spacing.md)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(exploredThemes, id: \.rawValue) { theme in
                            HStack(spacing: Spacing.sm) {
                                EditorialDivider(color: Palette.rose, width: 26)
                                    .frame(width: 26)
                                Text(String.ember("journal.theme.\(theme.rawValue)"))
                                    .font(Typography.editorial(.body))
                                    .foregroundStyle(Palette.ink)
                            }
                            .padding(.vertical, 9)
                        }
                    }
                    .padding(.top, Spacing.sm)
                }

                if !store.allJournalEntries.isEmpty {
                    SectionEyebrow(key: "progress.history")
                        .padding(.top, Spacing.xl)

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
                    .padding(.top, Spacing.sm)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PaperBackground(tint: Palette.paper))
        .navigationBarTitleDisplayMode(.inline)
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
