import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {
  static let premiumProductId = "crushyourraceprosubscription"

  @Published private(set) var subscriptions: [Product] = []
  @Published private(set) var purchasedSubscriptions: [Product] = []

  private var updateListenerTask: Task<Void, Error>?

  init() {
    updateListenerTask = listenForTransactions()

    Task {
      await loadProducts()
    }
  }

  deinit {
    updateListenerTask?.cancel()
  }

  func loadProducts() async {
    do {
      print("Starting product load...")
      let storeKitConfig = try StoreKit.Configuration.current
      print("StoreKit configuration loaded: \(storeKitConfig)")

      subscriptions = try await Product.products(for: [Self.premiumProductId])
      print("Product load completed. Found \(subscriptions.count) products")

      for product in subscriptions {
        print("Product details:")
        print("- ID: \(product.id)")
        print("- Type: \(product.type)")
        print("- Price: \(product.price)")
        print("- Subscription period: \(product.subscription?.subscriptionPeriod.unit ?? .month)")
      }
    } catch {
      print("Product load failed with error: \(error)")
      if let skError = error as? SKError {
        print("SKError code: \(skError.code.rawValue)")
        print("SKError description: \(skError.localizedDescription)")
        print("SKError debug description: \(skError.errorDescription)")
      }
    }
  }

  func purchase() async throws {
    print("Starting purchase flow...")
    guard let subscription = subscriptions.first else {
      print("No subscription product found")
      throw StoreError.productNotFound
    }

    print("Found subscription product: \(subscription.id)")
    let result = try await subscription.purchase()
    print("Purchase result received: \(result)")

    switch result {
    case .success(let verification):
      print("Purchase succeeded, verifying transaction...")
      let transaction = try checkVerified(verification)
      print("Transaction verified, updating backend...")
      if let token = UserDefaults.standard.string(forKey: "jwt_token") {
        try await updateBackendPremiumStatus(token: token)
        print("Backend updated successfully")
      }
      await transaction.finish()
      await loadProducts()
      print("Purchase flow completed successfully")
    case .userCancelled:
      print("User cancelled purchase")
      throw StoreError.userCancelled
    case .pending:
      print("Purchase is pending")
      throw StoreError.pending
    @unknown default:
      print("Unknown purchase result")
      throw StoreError.unknown
    }
  }

  private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
      throw StoreError.failedVerification
    case .verified(let safe):
      return safe
    }
  }

  private func listenForTransactions() -> Task<Void, Error> {
    return Task.detached {
      for await result in Transaction.updates {
        do {
          let transaction = try await self.checkVerified(result)
          await transaction.finish()
        } catch {
          print("Transaction failed verification")
        }
      }
    }
  }

  private func updateBackendPremiumStatus(token: String) async throws {
    guard let url = URL(string: "\(APIManager.shared.apiURL)/premium/") else {
      throw StoreError.unknown
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let payload = ["premium": true]
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)

    let (_, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      (200..<300).contains(httpResponse.statusCode)
    else {
      throw StoreError.failedToUpdateBackend
    }
  }
}

enum StoreError: LocalizedError {
  case failedVerification
  case productNotFound
  case userCancelled
  case pending
  case unknown
  case failedToUpdateBackend

  var errorDescription: String? {
    switch self {
    case .failedVerification:
      return "Transaction verification failed"
    case .productNotFound:
      return "Product not found"
    case .userCancelled:
      return "Purchase was cancelled"
    case .pending:
      return "Purchase is pending"
    case .failedToUpdateBackend:
      return "Failed to activate subscription"
    case .unknown:
      return "An unknown error occurred"
    }
  }
}
