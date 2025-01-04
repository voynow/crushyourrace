import UIKit
import os
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.crushyourrace", category: "AppDelegate")

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    logger.info(
      "Application did finish launching with options: \(String(describing: launchOptions))")
    return true
  }

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    NotificationManager.shared.updateDeviceToken(tokenString)
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    logger.error("Failed to register for remote notifications: \(error.localizedDescription)")
  }

  private func registerForPushNotifications() {
    UNUserNotificationCenter.current().delegate = self
    
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { [weak self] granted, error in
      guard let self = self else { return }
      
      if granted {
        self.logger.info("Notification permission granted")
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      } else if let error = error {
        self.logger.error("Error requesting notification permission: \(error.localizedDescription)")
      }
    }
  }
}
