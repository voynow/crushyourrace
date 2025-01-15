import AuthenticationServices
import SwiftUI

struct LandingPageView: View {
  @EnvironmentObject var appState: AppState
  @ObservedObject var authManager: AuthManager

  init(authManager: AuthManager) {
    self.authManager = authManager
  }

  var body: some View {
    ZStack {
      VStack(spacing: 8) {
        OnboardingCarousel(showCloseButton: false)

        VStack(spacing: 16) {
          signInWithStravaButton
          signInWithAppleButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
      }

      if authManager.showAlert {
        ToastView(
          message: "Install the Strava app or use another login method to continue.",
          isShowing: $authManager.showAlert
        )
        .transition(.move(edge: .top))
        .animation(.easeInOut, value: authManager.showAlert)
      }
    }
    .background(ColorTheme.black)
    .onOpenURL { url in
      authManager.handleURL(url)
    }
  }

  private var signInWithStravaButton: some View {
    Button(action: {
      authManager.authenticateWithStrava()
    }) {
      ZStack(alignment: .topTrailing) {
        HStack {
          Image("stravaIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 20)
          Text("Sign in with Strava")
            .font(.system(size: 19))
            .fontWeight(.medium)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(ColorTheme.primary)
        .foregroundColor(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)

        Text("Recommended")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(ColorTheme.primaryDark)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(ColorTheme.primaryLight)
          .cornerRadius(8)
          .offset(x: -8, y: -12)
      }
    }
  }

  private var signInWithAppleButton: some View {
    SignInWithAppleButton(
      onRequest: { request in
        request.requestedScopes = [.email]
      },
      onCompletion: { result in
        authManager.handleAppleSignIn(result)
      }
    )
    .signInWithAppleButtonStyle(.black)
    .frame(height: 50)
    .cornerRadius(12)
  }
}

struct ToastView: View {
  let message: String
  @Binding var isShowing: Bool

  var body: some View {
    VStack {
      HStack(spacing: 12) {
        Image(systemName: "exclamationmark.circle.fill")
          .foregroundColor(.white)

        Text(message)
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.white)

        Spacer()

        Button(action: { isShowing = false }) {
          Image(systemName: "xmark")
            .foregroundColor(.white)
        }
      }
      .padding()
      .background(ColorTheme.primary.opacity(0.8))
      .cornerRadius(12)
      .shadow(radius: 4)
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}

#Preview {
  let appState = AppState()
  return LandingPageView(authManager: AuthManager(appState: appState))
    .environmentObject(appState)
}
