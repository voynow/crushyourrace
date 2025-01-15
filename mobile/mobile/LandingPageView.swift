import AuthenticationServices
import SwiftUI

struct LandingPageView: View {
  @EnvironmentObject var appState: AppState
  @ObservedObject var authManager: AuthManager

  init(authManager: AuthManager) {
    self.authManager = authManager
  }

  var body: some View {
    VStack(spacing: 8) {
      OnboardingCarousel(showCloseButton: false)

      VStack(spacing: 16) {
        signInWithStravaButton
        signInWithAppleButton
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 32)
    }
    .background(ColorTheme.black)
    .onOpenURL { url in
      authManager.handleURL(url)
    }
    .alert(isPresented: $authManager.showAlert) {
      Alert(
        title: Text("Strava App Not Installed"),
        message: Text("Please install the Strava app to continue."),
        dismissButton: .default(Text("OK"))
      )
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
          .foregroundColor(ColorTheme.black)
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

#Preview {
  let appState = AppState()
  return LandingPageView(authManager: AuthManager(appState: appState))
    .environmentObject(appState)
}
