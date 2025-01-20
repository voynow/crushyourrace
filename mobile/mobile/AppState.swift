import SwiftUI
import UserNotifications

enum AuthStrategy: String {
  case apple
  case strava
}

class AppState: ObservableObject {
  @Published var status: AppStateStatus = .loggedOut
  @Published var jwtToken: String? = nil
  @Published var userId: String? = nil
  @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
  @Published var showProfile: Bool = false
  @Published var selectedTab: Int = 0
  @Published var showPaywall: Bool = false
  @Published var authStrategy: AuthStrategy = {
    let storedStrategy = UserDefaults.standard.string(forKey: "auth_strategy")
    if let storedStrategy = storedStrategy,
      let strategy = AuthStrategy(rawValue: storedStrategy)
    {
      return strategy
    }
    return .strava
  }()
  {
    didSet {
      UserDefaults.standard.set(authStrategy.rawValue, forKey: "auth_strategy")
    }
  }

  func setGeneratingPlanState() {
    status = .generatingPlan
    showProfile = false
    selectedTab = 1
  }

  func checkNotificationStatus() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        self.notificationStatus = settings.authorizationStatus
      }
    }
  }

  func requestNotificationPermission() {
    UNUserNotificationCenter.current().delegate =
      UIApplication.shared.delegate as? UNUserNotificationCenterDelegate

    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
      granted, error in
      DispatchQueue.main.async {
        self.checkNotificationStatus()
        if granted {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }
  }

  func clearAuthState() {
    status = .loggedOut
    jwtToken = nil
    userId = nil
    authStrategy = .strava
    UserDefaults.standard.removeObject(forKey: "jwt_token")
    UserDefaults.standard.removeObject(forKey: "user_id")
    UserDefaults.standard.removeObject(forKey: "auth_strategy")
  }

  func setShowPaywall() {
    guard let token = jwtToken else { return }
    print("Triggering paywall check")

    Task {
      do {
        let status = try await PremiumManager.checkStatus(token: token)
        DispatchQueue.main.async {
          self.showPaywall = status == .needsPaywall
        }
      } catch {
        print("Failed to check premium status: \(error)")
      }
    }
  }
}
