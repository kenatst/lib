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
                ZStack {
                    EditorialSketchView(
                        scene: .almostTouching,
                        color: Palette.wine,
                        wash: Palette.blush,
                        lineWidth: 1.45
                    )
                    SketchMotifView(
                        journey: .ourDesire,
                        evolution: 0.45,
                        lineWidth: 1.25,
                        inkOpacity: 0.45
                    )
                    .padding(54)
                }
                .frame(height: 224)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.md)

                SectionEyebrow(key: "couple.eyebrow")
                    .padding(.top, Spacing.md)

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
                    .padding(.vertical, Spacing.md)
                    .padding(.leading, Spacing.md)
                    .padding(.trailing, Spacing.sm)
                    .background(Palette.blush.opacity(0.32))
                    .overlay(alignment: .leading) {
                        Rectangle().fill(Palette.wine).frame(width: 2)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.md)

                // Honest labeling: same-device spaces are a demo reality, not
                // inter-partner privacy across devices.
                Text("couple.demo.note")
                    .emberCaption()
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.sm)

                Text("couple.role.question")
                    .font(Typography.editorial(.title3))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, Spacing.xl)

                VStack(spacing: 0) {
                    ForEach(Array(EmberStore.CoupleRole.allCases.enumerated()), id: \.element.rawValue) { index, role in
                        QuietOption(
                            textKey: role.nameKey,
                            mark: index == 0 ? "I" : "II"
                        ) {
                            guard bothAgreed else { return }
                            Haptics.selection()
                            store.setCoupleRole(role)
                            router.replace(with: .coupleSpace)
                        }
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
