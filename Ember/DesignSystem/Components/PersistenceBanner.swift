import SwiftUI

// MARK: - PersistenceBanner
//
// Rendered by RootView whenever storage is NOT durably ready. This is the
// product surface of the persistence truth machine:
//   * .unavailable(unreadable) → data exists but can't be opened; retry the
//     READ on activation (usually the device was simply locked).
//   * .unavailable(corrupt)    → quarantined untouched; retry offers recovery.
//   * .volatile                → last write failed; content is session-only.
//     Retry the WRITE on activation (never reload — memory is authoritative).

struct PersistenceBanner: View {

    @Environment(EmberStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        switch store.persistenceStatus {
        case .ready:
            EmptyView()
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.retryLoading() }
                }
        case .volatile:
            banner(bodyKey: "persistence.banner.body.volatile", icon: "hourglass")
                // Volatile recovery = RETRY THE SAVE (memory is authoritative;
                // reloading would discard unsaved private writing).
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { _ = store.retrySaving() }
                }
        case .unavailable:
            banner(
                bodyKey: store.persistenceStatus == .unavailable(.unreadable)
                    ? "persistence.banner.body.unreadable"
                    : "persistence.banner.body.corrupt",
                icon: "externaldrive.badge.exclamationmark"
            )
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { store.retryLoading() }
            }
        }
    }

    private func banner(bodyKey: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label {
                Text("persistence.banner.title")
                    .font(Typography.ui(.subheadline, weight: .semibold))
                    .foregroundStyle(Palette.cream)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(Palette.blush)
            }

            Text(bodyKey)
                .font(Typography.ui(.footnote))
                .foregroundStyle(Palette.cream.opacity(0.9))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Palette.deepWine)
        )
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}
