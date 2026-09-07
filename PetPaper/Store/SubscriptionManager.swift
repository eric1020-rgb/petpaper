import Foundation
import Observation
import StoreKit

/// StoreKit 2 client for **寵物壁紙 Plus / PetPaper Plus**.
///
/// Entitlement is derived from `Transaction.currentEntitlements`.
/// Receipts are not stored. A derived `AppGroupStore.hasPlusAccess` flag is
/// written so the Home Screen widget can choose rest vs premium poses.
@MainActor
@Observable
final class SubscriptionManager {
    static let monthlyProductID = "com.eric1020.petpaper.plus.monthly"

    /// Fallback when StoreKit has not returned a localized price yet.
    /// App Store Connect should use the **$0.99 USD** monthly tier (closest to US$1).
    static let fallbackDisplayPrice = "US$0.99"

    var products: [Product] = []
    var hasPlusAccess = false
    var isInIntroOfferPeriod = false
    var isEligibleForIntroOffer = false
    var isLoading = true
    var isPurchasing = false
    var isRestoring = false
    var isPaywallPresented = false
    var lastErrorMessage: String?
    var restoreAlert: RestoreAlert?

    private var updatesTask: Task<Void, Never>?

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    /// Localized price from StoreKit, or the $0.99 fallback.
    var displayPrice: String {
        monthlyProduct?.displayPrice ?? Self.fallbackDisplayPrice
    }

    var plusStatus: PlusStatus {
        if isLoading { return .loading }
        if hasPlusAccess {
            return isInIntroOfferPeriod ? .trial : .subscribed
        }
        return .inactive
    }

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
        Task { await refresh() }
    }

    func presentPaywall() {
        lastErrorMessage = nil
        isPaywallPresented = true
    }

    func dismissPaywall() {
        isPaywallPresented = false
    }

    func isPetUnlocked(_ petID: String) -> Bool {
        hasPlusAccess || PetCharacter.isFree(petID)
    }

    func canUsePhotoImport() -> Bool { hasPlusAccess }

    /// Widget idle / premium poses (and any future advanced motion) are Plus.
    /// Follow mode on the wallpaper canvas stays free.
    func canUsePremiumMotion() -> Bool { hasPlusAccess }

    /// Returns `true` when the feature is unlocked. Otherwise presents the paywall.
    @discardableResult
    func requestPhotoImport() -> Bool {
        guard canUsePhotoImport() else {
            presentPaywall()
            return false
        }
        return true
    }

    @discardableResult
    func requestPet(_ petID: String) -> Bool {
        guard isPetUnlocked(petID) else {
            presentPaywall()
            return false
        }
        return true
    }

    @discardableResult
    func requestPremiumMotion() -> Bool {
        guard canUsePremiumMotion() else {
            presentPaywall()
            return false
        }
        return true
    }

    func refresh() async {
        isLoading = products.isEmpty && !hasPlusAccess
        lastErrorMessage = nil
        do {
            products = try await Product.products(for: [Self.monthlyProductID])
        } catch {
            lastErrorMessage = String(localized: "paywall.error.load")
        }
        await refreshEntitlements()
        await refreshIntroEligibility()
        isLoading = false
    }

    func purchaseMonthly() async {
        guard !isPurchasing else { return }
        lastErrorMessage = nil
        guard let product = monthlyProduct else {
            lastErrorMessage = String(localized: "paywall.error.load")
            await refresh()
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                await refreshIntroEligibility()
                if hasPlusAccess {
                    isPaywallPresented = false
                }
            case .userCancelled:
                break
            case .pending:
                lastErrorMessage = String(localized: "paywall.error.pending")
            @unknown default:
                lastErrorMessage = String(localized: "paywall.error.purchase")
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        guard !isRestoring else { return }
        lastErrorMessage = nil
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            await refreshIntroEligibility()
            if hasPlusAccess {
                restoreAlert = RestoreAlert(
                    title: String(localized: "paywall.restore.ok.title"),
                    body: String(localized: "paywall.restore.ok.body")
                )
            } else {
                restoreAlert = RestoreAlert(
                    title: String(localized: "paywall.restore.none.title"),
                    body: String(localized: "paywall.restore.none.body")
                )
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func refreshEntitlements() async {
        var entitled = false
        var intro = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.productID == Self.monthlyProductID else { continue }
            guard transaction.revocationDate == nil else { continue }
            entitled = true
            if #available(iOS 17.2, *) {
                intro = transaction.offerType == .introductory
            }
        }
        hasPlusAccess = entitled
        isInIntroOfferPeriod = entitled && intro
        if AppGroupStore.hasPlusAccess != entitled {
            AppGroupStore.hasPlusAccess = entitled
            AppGroupStore.reloadDesktopPetWidget()
        }
    }

    private func refreshIntroEligibility() async {
        guard let product = monthlyProduct, let subscription = product.subscription else {
            isEligibleForIntroOffer = false
            return
        }
        isEligibleForIntroOffer = await subscription.isEligibleForIntroOffer
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(transactionResult)
            await transaction.finish()
            await refreshEntitlements()
            await refreshIntroEligibility()
        } catch {
            lastErrorMessage = String(localized: "paywall.error.purchase")
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.unverified
        case .verified(let safe):
            return safe
        }
    }
}

enum PlusStatus: Equatable {
    case loading
    case inactive
    case trial
    case subscribed
}

struct RestoreAlert: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let body: String
}

enum SubscriptionError: LocalizedError {
    case unverified

    var errorDescription: String? {
        String(localized: "paywall.error.unverified")
    }
}
