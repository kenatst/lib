import SwiftUI

// MARK: - PersistenceBanner
//
// Rendered by RootView whenever storage is NOT ready. This is the product
// surface of the persistence truth machine: if a locked-device launch or a
// corrupt file makes saving impossible, the user is told plainly — and the
// app retries reading on every activation, because the situation is usually
// transient (the device was simply locked).

struct PersistenceBanner: View {

    @Environment(EmberStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        switch store.persistenceStatus {
        case .ready:
            // Retry loading whenever we become active — recovery replaces the
            // in-memory placeholder wholesale once the real file reads.
            EmptyView()
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.retryLoading() }
                }
        case .unavailable(let reason):
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label {
                    Text("persistence.banner.title")
                        .font(Typography.ui(.subheadline, weight: .semibold))
                        .foregroundStyle(Palette.cream)
                } icon: {
                    Image(systemName: "externaldrive.badge.exclamationmark")
                        .foregroundStyle(Palette.blush)
                }

                Text(reason == .unreadable
                     ? "persistence.banner.body.unreadable"
                     : "persistence.banner.body.corrupt")
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
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { store.retryLoading() }
            }
        }
    }
}
