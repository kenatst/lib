import SwiftUI
import StoreKit

// MARK: - PaywallView
//
// The quietest possible ask. No countdowns, no fake discounts, no flashing.
// One product, one price, restore always visible. Demonstrates value by
// naming what the journey already gave them.

struct PaywallView: View {

    @Environment(StoreService.self) private var storeService
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Static safe URL strategy: parsed once at init from a compile-time
    /// literal; a malformed constant is impossible to ship silently.
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")

    @State private var isPurchasing = false
    @State private var showRestoreEmpty = false
    @State private var appeared = false

    private var product: Product? {
        storeService.products.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                motifHeader
                titleBlock
                benefits
                purchaseBlock
                legalFooter
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
            .opacity(appeared ? 1 : 0)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(Text("paywall.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "common.close")) {
                    router.pop()
                }
                .font(Typography.ui(.footnote))
            }
        }
        .onAppear {
            guard !appeared else { return }
            Task { await storeService.loadProducts() }
            withAnimation(Motion.resolved(Motion.ink, reduceMotion: reduceMotion)) {
                appeared = true
            }
        }
        .alert(
            Text("paywall.restore.empty.title"),
            isPresented: $showRestoreEmpty
        ) {
            Button(String(localized: "common.ok")) { showRestoreEmpty = false }
        } message: {
            Text("paywall.restore.empty.body")
        }
        .onChange(of: storeService.restoreFoundNothing) { _, foundNothing in
            // Only an explicit restore with no prior purchase opens this.
            if foundNothing { showRestoreEmpty = true }
        }
    }

    // MARK: Pieces

    private var motifHeader: some View {
        EditorialSketchView(
            scene: .ribbon,
            color: Palette.wine,
            wash: Palette.blush,
            lineWidth: 1.55
        )
            .frame(height: 190)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.md)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionEyebrow(key: "paywall.eyebrow")

            Text("paywall.headline")
                .font(Typography.editorial(.largeTitle))
                .foregroundStyle(Palette.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Text("paywall.subline")
                .emberProse(.callout, color: Palette.mutedInk)
                .padding(.top, Spacing.xs)
        }
        .padding(.top, Spacing.lg)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(Array(PremiumFeature.allCases.prefix(3)), id: \.rawValue) { feature in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    EditorialDivider(color: Palette.rose, width: 24)
                        .frame(width: 24)

                    Text(String.ember(feature.nameKey))
                        .font(Typography.editorial(.body))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.top, Spacing.lg)
    }

    @ViewBuilder
    private var purchaseBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if storeService.entitlement.isActive {
                ownedState
            } else if let product {
                priceAndButton(product)
            } else if storeService.lastError != nil {
                unavailableState
            } else {
                ProgressView()
                    .tint(Palette.rose)
                    .padding(.vertical, Spacing.lg)
            }
        }
        .padding(.top, Spacing.xl)
    }

    private func priceAndButton(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("paywall.price.note")
                .emberCaption()

            EmberButton(
                title: String.ember("paywall.cta", product.displayPrice),
                style: .primary,
                isLoading: isPurchasing
            ) {
                startPurchase(product)
            }

            Text("paywall.price.fineprint")
                .emberCaption()
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task {
                    await storeService.restore()
                }
            } label: {
                Text("paywall.restore")
                    .font(Typography.ui(.subheadline))
                    .foregroundStyle(Palette.wine)
                    .underline()
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, Spacing.xs)

            if let error = storeService.lastError {
                Text(errorText(error))
                    .emberCaption(Palette.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var ownedState: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label {
                Text("paywall.owned")
                    .emberProse(.callout, color: Palette.wine)
            } icon: {
                Image(systemName: "checkmark.seal")
                    .foregroundStyle(Palette.rose)
            }
            EmberButton(title: String(localized: "common.continue"), style: .secondary) {
                router.popToRoot()
            }
        }
    }

    private var unavailableState: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("paywall.unavailable")
                .emberProse(.callout, color: Palette.mutedInk)
            Button {
                Task { await storeService.loadProducts() }
            } label: {
                Text("paywall.retry")
                    .font(Typography.ui(.subheadline))
                    .foregroundStyle(Palette.wine)
                    .underline()
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var legalFooter: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("paywall.legal.privacy")
                .emberCaption(Palette.softRose)

            // Auto-renewable subscriptions require a functional Terms link.
            if let termsURL = Self.termsURL {
                Link(destination: termsURL) {
                    Text("paywall.legal.terms.link")
                        .emberCaption(Palette.softRose)
                        .underline()
                        .frame(minHeight: 24, alignment: .leading)
                }
            }
        }
        .padding(.top, Spacing.xxl)
    }

    // MARK: Actions

    private func startPurchase(_ product: Product) {
        Haptics.selection()
        isPurchasing = true
        Task {
            let unlocked = await storeService.purchase(product)
            isPurchasing = false
            if unlocked {
                Haptics.warm()
                try? await Task.sleep(for: .seconds(0.6))
                router.pop()
            }
        }
    }

    private func errorText(_ error: StoreService.StoreError) -> String {
        switch error {
        case .userCancelled:
            return String(localized: "paywall.error.cancelled")
        case .pending:
            return String(localized: "paywall.error.pending")
        case .productNotFound:
            return String(localized: "paywall.error.noproducts")
        default:
            return String(localized: "paywall.unavailable")
        }
    }
}

#Preview {
    NavigationStack {
        PaywallView()
    }
    .environment(StoreService())
    .environment(AppRouter())
}
