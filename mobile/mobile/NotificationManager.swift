import Foundation
import os

class NotificationManager {
  static let shared = NotificationManager()
  private var deviceToken: String?
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.crushyourrace", category: "NotificationManager")

  private init() {}

  func updateDeviceToken(_ token: String) {
    deviceToken = token
    logger.info("NotificationManager: Received new device token")
    sendTokenToServer()
  }

  private func sendTokenToServer() {
    guard let token = deviceToken,
      let jwtToken = UserDefaults.standard.string(forKey: "jwt_token")
    else {
      logger.error("NotificationManager: Missing device token or JWT token")
      return
    }

    APIManager.shared.updateDeviceToken(token: jwtToken, deviceToken: token) { result in
      switch result {
      case .success:
        self.logger.info("NotificationManager: Successfully registered device token with server")
      case .failure(let error):
        self.logger.error(
          "NotificationManager: Failed to register device token: \(error.localizedDescription)")
      }
    }
  }
}
