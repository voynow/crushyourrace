import SwiftUI

struct PremiumManager {
  static func checkStatus(token: String) async throws -> PremiumStatus {
    let isInFreeTrial = try await withCheckedThrowingContinuation { continuation in
      APIManager.shared.checkFreeTrialStatus(token: token) { result in
        switch result {
        case .success(let isInFreeTrial):
          continuation.resume(returning: isInFreeTrial)
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }

    if isInFreeTrial {
      return .freeTrial
    }

    let isPremium = try await withCheckedThrowingContinuation { continuation in
      APIManager.shared.checkPremiumStatus(token: token) { result in
        switch result {
        case .success(let isPremium):
          continuation.resume(returning: isPremium)
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
    return isPremium ? .premium : .needsPaywall
  }
}
