import SwiftUI

// MARK: - CoupleSpaceView
//
// One partner's private space: today's asymmetric step, private reflection,
// and — only by explicit hand-off — a note for the other partner.
// There is no UI path to the other partner's reflections. By construction.

struct CoupleSpaceView: View {

    @Environment(EmberStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var note = ""
    @State private var handOffComplete = false

    /// The partner whose space is open (persisted so relaunch reopens theirs).
    private var role: EmberStore.CoupleRole {
        store.state.coupleRole ?? .partnerOne
    }

    private var nextDay: Int {
        min(JourneyCatalog.totalDays, (store.state.completedDays.max() ?? 0) + 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                asymmetricStep
                handedOffNoteSection
                handOffComposer
                privacyFooter
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(Text(String.ember("couple.space.private", roleName)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "couple.switch.space")) {
                    Haptics.selection()
                    store.setCoupleRole(role.other)
                    // Clear composer state when switching spaces.
                    note = ""
                    handOffComplete = false
                }
                .font(Typography.ui(.footnote))
            }
        }
    }

    private var roleName: String {
        String(localized: String.LocalizationValue(role.nameKey))
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SketchMotifView(journey: .ourDesire, evolution: motifEvolution)
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .opacity(0.85)

            Text(String.ember("couple.space.private", roleName))
                .font(Typography.editorial(.title2))
                .foregroundStyle(Palette.ink)
                .padding(.top, Spacing.sm)
        }
        .padding(.top, Spacing.md)
    }

    private var motifEvolution: Double {
        Double(store.state.completedDays.count) / Double(JourneyCatalog.totalDays) + 0.35
    }

    // MARK: Asymmetric step

    private var asymmetricStep: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("couple.shared.tonight")
                .emberCaption(Palette.rose)
                .kerning(1.8)
                .textCase(.uppercase)
                .padding(.top, Spacing.lg)

            Text(String.ember(asymmetricKey(for: role)))
                .emberProse(.title3)

            Text("couple.asymmetric.notice")
                .emberCaption()
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.xs)
        }
        .padding(.top, Spacing.xs)
    }

    /// Asymmetric challenges: each partner receives their own step. The keys
    /// differ per role; neither partner needs to see the other's instruction.
    private func asymmetricKey(for role: EmberStore.CoupleRole) -> String {
        let day = min(nextDay, JourneyCatalog.totalDays)
        return "couple.asymmetric.day.\(day).\(role.rawValue)"
    }

    // MARK: Handed-off note (received)

    @ViewBuilder
    private var handedOffNoteSection: some View {
        if let received = store.takeHandedOffNote(for: role) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("couple.invite.header")
                    .emberCaption(Palette.rose)
                    .kerning(1.8)
                    .textCase(.uppercase)
                    .padding(.top, Spacing.xl)

                Text(received)
                    .emberProse(.callout, color: Palette.wine)
                    .italic()
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(Palette.blush.opacity(0.4))
                    )
                    .padding(.top, Spacing.xs)
            }
        }
    }

    // MARK: Hand-off composer (given)

    private var handOffComposer: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("couple.privacy.rule")
                .emberCaption()
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.lg)

            if handOffComplete {
                Label {
                    Text("session.reflect.saved")
                        .emberCaption(Palette.mutedInk)
                } icon: {
                    Image(systemName: "hand.point.up.left")
                        .foregroundStyle(Palette.rose)
                }
                .padding(.top, Spacing.sm)
                .transition(.opacity)
            } else {
                TextField(
                    String(localized: "couple.shared.tonight"),
                    text: $note,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .font(Typography.editorial(.body))
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.sentences)
                .textContentType(nil)
                .privacySensitive()
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(Palette.cream.opacity(0.9))
                        .strokeBorder(Palette.hairline, lineWidth: 1)
                )
                .padding(.top, Spacing.sm)

                EmberButton(title: String(localized: "common.continue"), style: .secondary) {
                    let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.handOffNote(trimmed, from: role)
                    Haptics.soft()
                    withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion)) {
                        handOffComplete = true
                    }
                }
                .padding(.top, Spacing.xs)
            }
        }
    }

    private var privacyFooter: some View {
        Text("couple.locked.other \(String(localized: String.LocalizationValue(role.other.nameKey)))")
            .emberCaption(Palette.softRose)
            .padding(.top, Spacing.xl)
    }
}

#Preview {
    NavigationStack {
        CoupleSpaceView()
    }
    .environment(previewCoupleStore())
    .environment(AppRouter())
}

private func previewCoupleStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.ourDesire)
    store.setCoupleRole(.partnerOne)
    return store
}
