import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss
    @State private var showsPrivacy = false

    var body: some View {
        @Bindable var subscriptions = subscriptions
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    priceCard
                    plusFeatures
                    freeFeatures
                    if let message = subscriptions.lastErrorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.coral)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    actions
                    legal
                    policyLinks
                }
                .padding(20)
                .padding(.bottom, 12)
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle(Text("paywall.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "paywall.notNow")) {
                        subscriptions.dismissPaywall()
                        dismiss()
                    }
                    .accessibilityHint(Text("a11y.paywall.dismiss"))
                }
            }
            .task {
                await subscriptions.refresh()
            }
            .alert(item: $subscriptions.restoreAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.body),
                    dismissButton: .default(Text("common.ok")) {
                        if subscriptions.hasPlusAccess {
                            subscriptions.dismissPaywall()
                            dismiss()
                        }
                    }
                )
            }
            .sheet(isPresented: $showsPrivacy) {
                PrivacyPolicyView()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(AppTheme.coral)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("paywall.title")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.ink)
                    Text("paywall.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("paywall.trial")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            Text(priceLine)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.coral)
            Text("paywall.renewal")
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var priceLine: String {
        let format = String(localized: "paywall.price.monthly")
        return String(format: format, locale: Locale.current, subscriptions.displayPrice)
    }

    private var plusFeatures: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("paywall.plus.title")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            featureRow("star.circle.fill", "paywall.feature.photo")
            featureRow("pawprint.circle.fill", "paywall.feature.pets")
            featureRow("hare.fill", "paywall.feature.motion")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var freeFeatures: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("paywall.free.title")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            Text("paywall.free.body")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func featureRow(_ systemImage: String, _ key: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(AppTheme.coral)
                .frame(width: 22)
            Text(LocalizedStringKey(key))
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                Task { await subscriptions.purchaseMonthly() }
            } label: {
                Group {
                    if subscriptions.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(subscribeTitle)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.coral)
            .disabled(subscriptions.isPurchasing || subscriptions.isRestoring || subscriptions.hasPlusAccess)
            .accessibilityLabel(Text(subscribeTitle))
            .accessibilityHint(Text("a11y.paywall.subscribe"))

            Button {
                Task { await subscriptions.restorePurchases() }
            } label: {
                if subscriptions.isRestoring {
                    ProgressView()
                } else {
                    Text("paywall.restore")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .disabled(subscriptions.isPurchasing || subscriptions.isRestoring)
            .accessibilityHint(Text("a11y.paywall.restore"))

            Button(String(localized: "paywall.notNow")) {
                subscriptions.dismissPaywall()
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.muted)
        }
    }

    private var subscribeTitle: String {
        if subscriptions.hasPlusAccess {
            return String(localized: "paywall.cta.subscribed")
        }
        if subscriptions.isEligibleForIntroOffer {
            return String(localized: "paywall.cta.trial")
        }
        let format = String(localized: "paywall.cta.subscribe")
        return String(format: format, locale: Locale.current, subscriptions.displayPrice)
    }

    private var legal: some View {
        Text(legalText)
            .font(.caption2)
            .foregroundStyle(AppTheme.muted)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(Text(legalText))
    }

    private var legalText: String {
        let format = String(localized: "paywall.legal")
        return String(format: format, locale: Locale.current, subscriptions.displayPrice)
    }

    private var policyLinks: some View {
        HStack(spacing: 16) {
            if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                Link(String(localized: "paywall.terms"), destination: url)
            }
            Button(String(localized: "paywall.privacy")) {
                showsPrivacy = true
            }
        }
        .font(.footnote.weight(.semibold))
        .tint(AppTheme.coral)
        .frame(maxWidth: .infinity)
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text("paywall.privacy.body")
                    .font(.body)
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
            .background(AppTheme.cream.ignoresSafeArea())
            .navigationTitle(Text("paywall.privacy.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.ok")) { dismiss() }
                }
            }
        }
    }
}

struct PlusLockBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
            Text("plus.badge")
        }
        .font(.caption2.weight(.bold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.coral)
        .foregroundStyle(.white)
        .clipShape(Capsule())
        .accessibilityLabel(Text("plus.badge"))
        .accessibilityHint(Text("a11y.plus.locked"))
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager())
}
