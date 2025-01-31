import SwiftUI

struct WaitingForGenerationView: View {
  @EnvironmentObject var appState: AppState
  @State private var dotPhase = 0
  @State private var opacity = 0.8
  @State private var showOnboarding = false
  @State private var currentThinkingPhase = 0
  @State private var pulseSize: CGFloat = 1.0
  let isAppleAuth: Bool

  private let thinkingPhrases = [
    "AI is thinking...",
    "Analyzing your training history...",
    "Our AI agent is impressed!",
    "Generating your training plan...",
    "Optimizing peak mileage and long runs...",
    "Your are going to crush it!",
    "Planning your upcoming week...",
    "Fine tuning to your preferences...",
    "This is going to be awesome...",
  ]

  var body: some View {
    ZStack {
      // Background
      ColorTheme.black.edgesIgnoringSafeArea(.all)

      // Minimal gradient overlay
      LinearGradient(
        gradient: Gradient(colors: [
          ColorTheme.primary.opacity(0.05),
          ColorTheme.black,
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .edgesIgnoringSafeArea(.all)

      // Content
      VStack(spacing: 40) {
        // Subtle branding
        HStack {
          Text("Crush ")
            .font(.system(size: 20, weight: .black))
            .foregroundColor(ColorTheme.primaryLight)
            + Text("Your Race")
            .font(.system(size: 20, weight: .black))
            .foregroundColor(ColorTheme.primary)
        }
        .opacity(0.8)
        .padding(.top, 32)

        Spacer()

        // AI Processing visualization
        ZStack {
          Circle()
            .stroke(ColorTheme.primary.opacity(0.15), lineWidth: 2)
            .frame(width: 80, height: 80)
            .scaleEffect(pulseSize)

          Circle()
            .fill(ColorTheme.primary.opacity(0.1))
            .frame(width: 60, height: 60)
            .scaleEffect(pulseSize)

          Image(systemName: "sparkles")
            .font(.system(size: 30))
            .foregroundColor(ColorTheme.primary)
        }

        VStack(spacing: 16) {
          Text("Building Your Training Plan")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(ColorTheme.white)

          Text(thinkingPhrases[currentThinkingPhase])
            .font(.system(size: 16))
            .foregroundColor(ColorTheme.lightGrey)
            .multilineTextAlignment(.center)
            .opacity(opacity)
            .animation(.easeInOut, value: currentThinkingPhase)
        }

        Spacer()

        // About button
        Button(action: { showOnboarding = true }) {
          HStack(spacing: 8) {
            Image(systemName: "info.circle")
            Text("About")
          }
          .font(.system(size: 16))
          .foregroundColor(ColorTheme.lightGrey)
          .padding(.vertical, 12)
          .padding(.horizontal, 24)
          .background(ColorTheme.darkDarkGrey)
          .cornerRadius(8)
        }
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 32)
    }
    .fullScreenCover(isPresented: $showOnboarding) {
      OnboardingCarousel(showCloseButton: true)
    }
    .onAppear {
      startThinkingAnimation()
      startPulseAnimation()
      handleInitialAuth()
    }
  }

  private func startThinkingAnimation() {
    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
      withAnimation {
        currentThinkingPhase = (currentThinkingPhase + 1) % thinkingPhrases.count
      }
    }
  }

  private func startPulseAnimation() {
    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
      pulseSize = 1.2
    }
  }

  private func handleInitialAuth() {
    if isAppleAuth {
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        completeGeneration()
      }
    } else {
      triggerRefreshUser()
    }
  }

  private func triggerRefreshUser() {
    guard let token = appState.jwtToken else {
      completeGeneration()
      return
    }

    APIManager.shared.refreshUser(token: token) { result in
      DispatchQueue.main.async {
        completeGeneration()
      }
    }
  }

  private func completeGeneration() {
    appState.showProfile = false
    appState.selectedTab = 1
    appState.status = .loggedIn
  }
}
