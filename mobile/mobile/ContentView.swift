import SwiftUI

struct ContentView: View {
  @EnvironmentObject var appState: AppState
  @StateObject private var authManager: AuthManager
  @State private var isInitialLoad = true
  @State private var hasCompletedInitialTransition = false

  init(appState: AppState) {
    _authManager = StateObject(wrappedValue: AuthManager(appState: appState))
    print("[ContentView] Initialized")
  }

  var body: some View {
    NavigationView {
      ZStack {
        ColorTheme.black.edgesIgnoringSafeArea(.all)

        Group {
          if !hasCompletedInitialTransition {
            LoadingView()
          } else {
            switch appState.status {
            case .newUser:
              OnboardingView()
                .transition(.opacity)
            case .loggedIn:
              ZStack {
                DashboardView()
                  .transition(.opacity)

                if appState.showProfile {
                  ProfileView(
                    isPresented: $appState.showProfile,
                    showProfile: $appState.showProfile
                  )
                  .zIndex(2)
                  .transition(.opacity)
                }
              }
            case .loggedOut:
              LandingPageView(authManager: authManager)
                .transition(.opacity)
            case .loading:
              LoadingView()
                .transition(.opacity)
            case .generatingPlan:
              WaitingForGenerationView(isAppleAuth: appState.authStrategy == .apple)
                .transition(.opacity)
            }
          }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.status)
      }
    }
    .navigationViewStyle(StackNavigationViewStyle())
    .onAppear {
      print("[ContentView] View appeared, current status: \(appState.status)")
      print("[ContentView] Auth strategy: \(appState.authStrategy)")

      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        withAnimation {
          hasCompletedInitialTransition = true
        }
      }
    }
  }

  private func handleGenerationComplete() {
    appState.showProfile = false
    appState.selectedTab = 1

    guard let token = appState.jwtToken else {
      print("No token found")
      return
    }

    APIManager.shared.refreshUser(token: token) { result in
      DispatchQueue.main.async {
        switch result {
        case .success:
          appState.status = .loggedIn
        case .failure(let error):
          print("Failed to generate plan: \(error.localizedDescription)")
        }
      }
    }
  }
}

struct AppleAuthView: View {
  @ObservedObject var appState: AppState

  var body: some View {
    Color.clear
      .onAppear {
        appState.showProfile = false
        appState.selectedTab = 1
        appState.status = .loggedIn
      }
  }
}

struct ContentView_Previews: PreviewProvider {
  @StateObject private var appState = AppState()

  static var previews: some View {
    ContentView(appState: AppState()).environmentObject(AppState())
  }
}
