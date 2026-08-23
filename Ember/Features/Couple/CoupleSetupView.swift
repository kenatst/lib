import SwiftUI

// MARK: - CoupleSetupView
//
// Our Desire pairing. Honest about the current reality: two spaces on one
// shared device. Privacy rules stated up front — private reflections never
// surface to a partner without an explicit hand-off.

struct CoupleSetupView: View {

    @Environment(EmberStore.self) private var store
    @Environment(AppRouter.self) private var router

    @State private var bothAgreed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SketchMotifView(journey: .ourDesire, evolution: 0.45)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.lg)
                    .opacity(0.9)

                Text("couple.setup.title")
                    .font(Typography.editorial(.largeTitle))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, Spacing.md)

                Text("couple.setup.body")
                    .emberProse()
                    .padding(.top, Spacing.sm)

                // Consent gate: both partners must have agreed before any
                // couple content is shown. Non-negotiable.
                Toggle(isOn: $bothAgreed) {
                    Text(String.ember("couple.consent"))
                        .emberProse(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .tint(Palette.wine)
                .padding(.vertical, Spacing.md)

                Text("couple.privacy.rule")
                    .font(Typography.ui(.footnote))
                    .foregroundStyle(Palette.wine)
                    .lineSpacing(4)
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(Palette.blush.opacity(0.35))
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.md)

                Text("couple.role.question")
                    .font(Typography.editorial(.title3))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, Spacing.xl)

                VStack(spacing: Spacing.sm) {
                    ForEach(EmberStore.CoupleRole.allCases, id: \.rawValue) { role in
                        Button {
                            guard bothAgreed else { return }
                            Haptics.selection()
                            store.setCoupleRole(role)
                            router.replace(with: .coupleSpace)
                        } label: {
                            HStack {
                                Text(String.ember(role.nameKey))
                                    .font(Typography.editorial(.body))
                                    .foregroundStyle(Palette.ink)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.softRose)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, Spacing.md)
                            .frame(minHeight: 52)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                    .fill(Palette.cream.opacity(0.85))
                                    .strokeBorder(Palette.hairline, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableStyle())
                        .disabled(!bothAgreed)
                        .opacity(bothAgreed ? 1 : 0.45)
                        .accessibilityHint(Text("couple.switch.space"))
                    }
                }
                .padding(.top, Spacing.md)

                Spacer(minLength: Spacing.xxl)
            }
            .padding(.horizontal, Spacing.md)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(Text("intention.ourDesire.name"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CoupleSetupView()
    }
    .environment(EmberStore())
    .environment(AppRouter())
}
