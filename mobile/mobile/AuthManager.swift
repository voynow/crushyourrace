import AuthenticationServices
import SwiftUI
import UIKit

class AuthManager: ObservableObject {
  private let clientID = "95101"
  private let redirectURI = "crushyourrace://www.crushyourrace.com"
  private let scope = "read_all,profile:read_all,activity:read_all"

  @Published var showAlert = false
  private var appState: AppState

  init(appState: AppState) {
    self.appState = appState
  }

  func authenticateWithStrava() {
    let appOAuthUrlStravaScheme = URL(
      string:
        "strava://oauth/mobile/authorize?client_id=\(clientID)&redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&response_type=code&approval_prompt=auto&scope=\(scope)"
    )!

    if UIApplication.shared.canOpenURL(appOAuthUrlStravaScheme) {
      UIApplication.shared.open(appOAuthUrlStravaScheme, options: [:])
    } else {
      showAlert = true
    }
  }

  func handleURL(_ url: URL) {
    if url.scheme == "crushyourrace" && url.host == "www.crushyourrace.com" {
      if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
        let code = queryItems.first(where: { $0.name == "code" })?.value
      {
        handleAuthorizationCode(code)
      }
    }
  }

  private func handleAuthorizationCode(_ code: String) {
    appState.status = .loading

    Task {
      do {
        guard let url = URL(string: "\(APIManager.shared.apiURL)/authenticate/") else {
          throw NSError(
            domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "code=\(code)".data(using: .utf8)

        let (data, response) = try await APIManager.shared.session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
          !(200..<300).contains(httpResponse.statusCode)
        {
          throw NSError(
            domain: "AuthError",
            code: httpResponse.statusCode,
            userInfo: [NSLocalizedDescriptionKey: "Authentication failed"]
          )
        }

        let authResponse = try JSONDecoder().decode(SignupResponse.self, from: data)

        if authResponse.success {
          UserDefaults.standard.set(authResponse.jwt_token, forKey: "jwt_token")
          UserDefaults.standard.set("strava", forKey: "auth_strategy")
          DispatchQueue.main.async {
            self.appState.jwtToken = authResponse.jwt_token
            self.appState.authStrategy = .strava
            if let isNewUser = authResponse.is_new_user, isNewUser {
              self.appState.status = .newUser
            } else {
              self.appState.status = .loggedIn
            }
          }
        } else {
          throw NSError(
            domain: "AuthError",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Authentication failed"]
          )
        }
      } catch {
        print("Error during authentication: \(error.localizedDescription)")
        DispatchQueue.main.async {
          self.appState.status = .loggedOut
        }
      }
    }
  }

  func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
    switch result {
    case .success(let auth):
      if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
        let userId = appleIDCredential.user
        let identityToken = appleIDCredential.identityToken
        let email = appleIDCredential.email

        Task {
          do {
            guard let url = URL(string: "\(APIManager.shared.apiURL)/authenticate/") else {
              throw NSError(
                domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(
              "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let formData = [
              "user_id": userId,
              "identity_token": String(data: identityToken ?? Data(), encoding: .utf8) ?? "",
              "email": email ?? "",
            ]
            .map { key, value in
              "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            }
            .joined(separator: "&")

            request.httpBody = formData.data(using: .utf8)

            let (data, response) = try await APIManager.shared.session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
              !(200..<300).contains(httpResponse.statusCode)
            {
              throw NSError(domain: "AuthError", code: httpResponse.statusCode)
            }

            let authResponse = try JSONDecoder().decode(SignupResponse.self, from: data)

            if authResponse.success {
              DispatchQueue.main.async {
                UserDefaults.standard.set(authResponse.jwt_token, forKey: "jwt_token")
                UserDefaults.standard.set(authResponse.user_id, forKey: "user_id")
                UserDefaults.standard.set("apple", forKey: "auth_strategy")
                self.appState.jwtToken = authResponse.jwt_token
                self.appState.userId = authResponse.user_id
                self.appState.authStrategy = .apple
                if let isNewUser = authResponse.is_new_user, isNewUser {
                  self.appState.status = .newUser
                } else {
                  self.appState.status = .loggedIn
                }
              }
            }
          } catch {
            print("Apple Sign In error: \(error.localizedDescription)")
            DispatchQueue.main.async {
              self.appState.status = .loggedOut
            }
          }
        }
      }
    case .failure(let error):
      print("Apple Sign In failed: \(error.localizedDescription)")
      DispatchQueue.main.async {
        self.appState.status = .loggedOut
      }
    }
  }
}
