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
      subscriptions = try await Product.products(for: [Self.premiumProductId])
    } catch {
      print("Product load failed: \(error)")
    }
  }

  func purchase(onSuccess: @escaping () -> Void) async throws {
    guard let subscription = subscriptions.first else {
      throw StoreError.productNotFound
    }

    let result = try await subscription.purchase()

    switch result {
    case .success(let verification):
      let transaction = try checkVerified(verification)
      if let token = UserDefaults.standard.string(forKey: "jwt_token") {
        await APIManager.shared.updatePremiumStatus(token: token, isPremium: true) { result in
          if case .failure(let error) = result {
            print("Failed to update subscription status: \(error)")
          }
        }
      }
      await transaction.finish()
      await loadProducts()
      onSuccess()
    case .userCancelled:
      throw StoreError.userCancelled
    case .pending:
      throw StoreError.pending
    @unknown default:
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
          print("Transaction verification failed: \(error)")
        }
      }
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
