import SwiftUI

struct WaitingForGenerationView: View {
  @EnvironmentObject var appState: AppState
  @State private var animationPhase = 0
  @State private var showOnboarding: Bool = false
  let isAppleAuth: Bool

  var body: some View {
    ZStack {
      ColorTheme.black.edgesIgnoringSafeArea(.all)

      VStack(spacing: 40) {
        Spacer()

        Text("Crush ")
          .font(.system(size: 28, weight: .black))
          .foregroundColor(ColorTheme.primaryLight)
          + Text("Your Race")
          .font(.system(size: 28, weight: .black))
          .foregroundColor(ColorTheme.primary)

        VStack(spacing: 10) {
          Text("We're generating your recommendations")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(ColorTheme.lightGrey)
            .multilineTextAlignment(.center)

          Text(
            "This typically takes 20-30 seconds but can take as long as one minute. Thank you for your patience!"
          )
          .font(.system(size: 14, weight: .light))
          .foregroundColor(ColorTheme.lightGrey)
          .multilineTextAlignment(.center)
        }

        VStack(spacing: 8) {
          HStack(spacing: 12) {
            ForEach(0..<3) { index in
              Circle()
                .fill(ColorTheme.primary)
                .frame(width: 12, height: 12)
                .scaleEffect(animationPhase == index ? 1.5 : 1.0)
                .opacity(animationPhase == index ? 1 : 0.5)
                .animation(.easeInOut(duration: 0.5), value: animationPhase)
            }
          }
        }
        .padding(.top, 20)

        Spacer()
      }
      .padding(.horizontal, 40)

      VStack {
        Spacer()
        Button(action: { showOnboarding = true }) {
          Text("About ")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(ColorTheme.midLightGrey2)
            + Text("Crush Your Race")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(ColorTheme.midLightGrey)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .overlay(
          Rectangle()
            .frame(height: 1)
            .foregroundColor(ColorTheme.darkGrey),
          alignment: .top
        )
        .background(ColorTheme.black)
        .padding(.bottom, 16)
      }
      .edgesIgnoringSafeArea(.bottom)
    }
    .fullScreenCover(isPresented: $showOnboarding) {
      OnboardingCarousel(showCloseButton: true)
    }
    .onAppear {
      withAnimation {
        startAnimation()
      }

      if isAppleAuth {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
          completeGeneration()
        }
      } else {
        triggerRefreshUser()
      }
    }
  }

  private func startAnimation() {
    Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { timer in
      withAnimation {
        animationPhase = (animationPhase + 1) % 3
      }
    }
  }

  private func triggerRefreshUser() {
    guard let token = appState.jwtToken else {
      print("No token found")
      completeGeneration()
      return
    }

    APIManager.shared.refreshUser(token: token) { result in
      DispatchQueue.main.async {
        switch result {
        case .success:
          completeGeneration()
        case .failure(let error):
          print("Failed to generate plan: \(error.localizedDescription)")
          completeGeneration()
        }
      }
    }
  }

  private func completeGeneration() {
    appState.showProfile = false
    appState.selectedTab = 1
    appState.status = .loggedIn
  }
}
