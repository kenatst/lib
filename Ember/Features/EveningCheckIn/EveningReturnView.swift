import SwiftUI

// MARK: - EveningReturnView
//
// The soft landing. One honest question, four answers, no judgment.
// The response tunes later days via CheckInAdapter.

struct EveningReturnView: View {

    let dayNumber: Int

    @Environment(EmberStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var response: CheckInResponse?
    @State private var saved = false
    @State private var appeared = false

    private var intention: DesireIntention? { store.state.intention }

    private var day: JourneyDay? {
        guard let intention else { return JourneyCatalog.day(dayNumber) }
        return JourneyCatalog.day(dayNumber, for: intention)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let day {
                    Text(String.ember(day.returnPromptKey))
                        .font(Typography.editorial(.largeTitle))
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Spacing.xl)
                        .opacity(appeared ? 1 : 0)
                } else {
                    Text("return.title")
                        .font(Typography.editorial(.largeTitle))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, Spacing.xl)
                }

                Text("return.subtitle")
                    .emberProse(.callout, color: Palette.mutedInk)
                    .padding(.top, Spacing.sm)

                VStack(spacing: Spacing.sm) {
                    ForEach(CheckInResponse.allCases, id: \.rawValue) { candidate in
                        ReturnOption(
                            textKey: candidate.textKey,
                            isSelected: response == candidate,
                            delay: 0.08 * Double(CheckInResponse.allCases.firstIndex(of: candidate) ?? 0)
                        ) {
                            choose(candidate)
                        }
                    }
                }
                .padding(.top, Spacing.xl)

                if saved {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Label {
                            Text("return.saved")
                                .emberProse(.callout, color: Palette.wine)
                        } icon: {
                            Image(systemName: "moon.stars")
                                .foregroundStyle(Palette.rose)
                        }
                        .transition(.opacity)

                        EmberButton(title: String(localized: "return.close.day")) {
                            closeDay()
                        }
                    }
                    .padding(.top, Spacing.xl)
                }

                Spacer(minLength: Spacing.xxl)
            }
            .padding(.horizontal, Spacing.md)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationBarBackButtonHidden(saved)
        .onAppear {
            guard !appeared else { return }
            withAnimation(Motion.resolved(Motion.ink, reduceMotion: reduceMotion)) {
                appeared = true
            }
        }
    }

    private func choose(_ candidate: CheckInResponse) {
        Haptics.selection()
        withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion)) {
            response = candidate
        }
        // Save immediately — one tap is enough; no "submit" ceremony.
        store.recordCheckIn(
            CheckIn(dayNumber: dayNumber, response: candidate, date: .now)
        )
        withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion, delay: 0.2)) {
            saved = true
        }
    }

    private func closeDay() {
        Haptics.soft()
        router.popToRoot()
    }
}

// MARK: - One return option

private struct ReturnOption: View {

    let textKey: String
    let isSelected: Bool
    let delay: TimeInterval
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                // Ink dot fills when chosen — quiet selection state.
                Circle()
                    .stroke(isSelected ? Palette.wine : Palette.rose.opacity(0.75), lineWidth: isSelected ? 1.6 : 1.4)
                    .background(Circle().fill(Palette.cream))
                    .frame(width: 13, height: 13)
                    .overlay {
                        Circle()
                            .fill(Palette.wine)
                            .frame(width: 6, height: 6)
                            .opacity(isSelected ? 1 : 0)
                    }

                Text(String(localized: String.LocalizationValue(textKey)))
                    .font(Typography.editorial(.body))
                    .foregroundStyle(isSelected ? Palette.wine : Palette.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(isSelected ? Palette.blush.opacity(0.55) : Palette.cream.opacity(0.85))
                    .strokeBorder(isSelected ? Palette.rose : Palette.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 14)
        .onAppear {
            guard !appeared else { return }
            withAnimation(Motion.resolved(Motion.gentle, reduceMotion: reduceMotion, delay: delay)) {
                appeared = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        EveningReturnView(dayNumber: 3)
    }
    .environment(previewReturnStore())
    .environment(AppRouter())
}

@MainActor
private func previewReturnStore() -> EmberStore {
    let store = EmberStore()
    store.setIntention(.ourDesire)
    store.markDayComplete(3)
    return store
}
