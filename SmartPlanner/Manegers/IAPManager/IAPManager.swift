import ApphudSDK
import StoreKit
import UIKit

enum SubsIDs {
    static let weeklySubsId =  "weeklySubsId2"
    static let monthlySubsId = "monthlySubsId2"
}

enum InAppPurchaseResult {
    case purchased
    case failed
    case restored
}

struct SubscriptionStatus {
    let isActive: Bool
    let isTrialPeriod: Bool
    let remainingTrialDays: Int?
}

extension SKProduct {
    var localizedPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)
    }
}

class IAPManager: NSObject {
    static let shared = IAPManager()
    
    var closure: ((InAppPurchaseResult) -> Void)?
    var products: [ApphudProduct] = []
    
    var hasActiveSubscription: Bool {
        //        false
        //        true
        Apphud.hasActiveSubscription()
    }
    
    private override init() {
        super.init()
        // Apphud уже настроен в AppDelegate, инициализируем и загружаем продукты
        fetchProducts()
    }
    
    // Предварительная загрузка продуктов при инициализации
    private func fetchProducts() {
        Task {
            // Получаем placements с ожиданием загрузки SKProducts
            let placements = await Apphud.placements(maxAttempts: 3)
            if let placement = placements.first, let paywall = placement.paywall, !paywall.products.isEmpty {
                self.products = paywall.products
                print("Продукты загружены: \(self.products.map { $0.productId })")

            } else {
                print("Нет доступных продуктов или paywall")
                self.products = []
            }
        }
    }
    
    // MARK: - Product Request
    func getProducts() -> [ApphudProduct] {
        return products
    }
    
    // MARK: - Purchases
    func purchase(productId: String, closure: @escaping (InAppPurchaseResult) -> Void) {
        self.closure = closure
        
        guard let product = products.first(where: { $0.productId == productId }) else {
            print("Продукт \(productId) не найден")
            closure(.failed)
            return
        }
        
        Task { @MainActor in
            Apphud.purchase(product, callback: { result in
                if let error = result.error {
                    print("Ошибка покупки: \(error.localizedDescription)")

                    closure(.failed)
                    return
                }
                
                if result.transaction != nil {
                    closure(.purchased)
                } else {
                    print("Покупка отменена или не завершена")
                    closure(.failed)
                }
            })
        }
    }
    
    func restorePurchases(closure: @escaping (InAppPurchaseResult) -> Void) {
        Task { @MainActor in
            let error = await Apphud.restorePurchases()
            if let error = error {
                print("Ошибка восстановления: \(error)")
               
                closure(.failed)
                return
            }
            
            if hasActiveSubscription || (Apphud.subscriptions()?.isEmpty == false) {
                closure(.restored)
            } else {
                closure(.failed)
            }
        }
    }
}
