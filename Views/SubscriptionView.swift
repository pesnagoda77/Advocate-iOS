import SwiftUI
import StoreKit

// MARK: - StoreKit подписка

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Advocate Pro")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Полный доступ ко всем функциям")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Функции
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "doc.text.fill", text: "Неограниченная генерация документов")
                        FeatureRow(icon: "cloud.fill", text: "Синхронизация между устройствами")
                        FeatureRow(icon: "bell.fill", text: "Напоминания о событиях")
                        FeatureRow(icon: "chart.bar.fill", text: "Расширенная аналитика")
                        FeatureRow(icon: "lock.shield.fill", text: "Защита паролем")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Тарифы
                    VStack(spacing: 12) {
                        ForEach(storeManager.products) { product in
                            SubscriptionCard(product: product, storeManager: storeManager)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Триал
                    Text("14 дней бесплатно, затем оплата")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    // Восстановление
                    Button("Восстановить покупки") {
                        storeManager.restorePurchases()
                    }
                    .font(.caption)
                    .foregroundColor(.indigo)
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("Подписка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.indigo)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct SubscriptionCard: View {
    let product: Product
    let storeManager: StoreManager
    
    var body: some View {
        Button {
            Task {
                await storeManager.purchase(product)
            }
        } label: {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.headline)
                        
                        Text(product.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.indigo)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Store Manager

class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isSubscribed = false
    
    private let productIDs = ["advocate_monthly", "advocate_yearly"]
    
    init() {
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: productIDs)
            await MainActor.run {
                self.products = products
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await MainActor.run {
                        self.isSubscribed = true
                    }
                    await transaction.finish()
                case .unverified(_, let error):
                    print("Unverified transaction: \(error)")
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Failed to purchase: \(error)")
        }
    }
    
    func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()
                await updateSubscriptionStatus()
            } catch {
                print("Failed to restore purchases: \(error)")
            }
        }
    }
    
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productType == .autoRenewableSubscription {
                    await MainActor.run {
                        self.isSubscribed = true
                    }
                }
            case .unverified(_, let error):
                print("Unverified transaction: \(error)")
            }
        }
    }
}
