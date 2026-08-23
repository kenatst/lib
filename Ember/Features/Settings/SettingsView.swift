import SwiftUI

// MARK: - SettingsView
//
// Privacy stated plainly, deletion front and center, journey restart.
// No accounts, no analytics, no dark patterns — EMBER keeps nothing anywhere
// but this device.

struct SettingsView: View {

    @Environment(EmberStore.self) private var store
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router

    @State private var showDeleteConfirmation = false
    @State private var showRestartConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                privacySection
                dataSection
                aboutSection
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(Text("settings.title"))
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            Text("settings.data.delete.confirm.title"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings.data.delete"), role: .destructive) {
                store.deleteEverything()
                Haptics.soft()
                appState.resetToFirstRun()
                router.popToRoot()
            }
            Button(String(localized: "common.keep"), role: .cancel) {}
        } message: {
            Text("settings.data.delete.confirm.message")
        }
        .confirmationDialog(
            Text("settings.journey.restart"),
            isPresented: $showRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings.journey.restart"), role: .destructive) {
                store.restartJourney()
                Haptics.soft()
                appState.resetToFirstRun()
                router.popToRoot()
            }
            Button(String(localized: "common.keep"), role: .cancel) {}
        } message: {
            Text("settings.journey.restart.confirm.message")
        }
    }

    // MARK: Sections

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("settings.privacy.header")
            Text("settings.privacy.body")
                .emberProse(.callout)
                .padding(.top, Spacing.xs)
        }
        .padding(.top, Spacing.lg)
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("settings.data.header")
                .padding(.bottom, Spacing.sm)

            destructiveRow(
                icon: "trash",
                titleKey: "settings.data.delete"
            ) {
                showDeleteConfirmation = true
            }

            row(icon: "arrow.triangle.2.circlepath", titleKey: "settings.journey.restart") {
                showRestartConfirmation = true
            }
        }
        .padding(.top, Spacing.lg)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("settings.about.header")
            Text("settings.about.body")
                .emberProse(.callout)
                .padding(.top, Spacing.xs)

            Text("settings.language.note")
                .emberCaption()

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text(String.ember("settings.version", version))
                    .emberCaption(Palette.softRose)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(.top, Spacing.xl)
    }

    // MARK: Rows

    private func sectionHeader(_ key: String) -> some View {
        Text(String.ember(key))
            .emberCaption(Palette.rose)
            .kerning(1.8)
            .textCase(.uppercase)
    }

    private func row(icon: String, titleKey: String, action: @escaping () -> Void) -> some View {
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

    private func destructiveRow(icon: String, titleKey: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Palette.wine)
                Text(String.ember(titleKey))
                    .font(Typography.ui(.subheadline, weight: .medium))
                    .foregroundStyle(Palette.wine)
                Spacer()
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.hairline).frame(height: 1)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(EmberStore())
    .environment(AppState())
    .environment(AppRouter())
}
