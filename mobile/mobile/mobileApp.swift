import SwiftUI

@main
struct mobileApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var appState = AppState()

  var body: some Scene {
    WindowGroup {
      ContentView(appState: appState)
        .environmentObject(appState)
        .onAppear {
          let token = UserDefaults.standard.string(forKey: "jwt_token")
          let userId = UserDefaults.standard.string(forKey: "user_id")

          if token != nil || userId != nil {
            appState.status = .loggedIn
            appState.jwtToken = token
            appState.userId = userId

            if let storedStrategy = UserDefaults.standard.string(forKey: "auth_strategy"),
              let strategy = AuthStrategy(rawValue: storedStrategy)
            {
              appState.authStrategy = strategy
            }

            // Delay the paywall popup
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
              appState.setShowPaywall()
            }
          } else {
            appState.status = .loggedOut
          }
        }
    }
  }

  private func checkAndRefreshToken() {
    if let token = UserDefaults.standard.string(forKey: "jwt_token") {
      APIManager.shared.refreshToken(token: token) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let newToken):
            appState.status = .loggedIn
            appState.jwtToken = newToken
            UserDefaults.standard.set(newToken, forKey: "jwt_token")
          case .failure(_):
            // Token refresh failed, user needs to log in again
            appState.status = .loggedOut
            appState.jwtToken = nil
            UserDefaults.standard.removeObject(forKey: "jwt_token")
          }
        }
      }
    }
  }
}
