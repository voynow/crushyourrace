import SwiftUI

struct PremiumSuccessAnimation: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @State private var scale = 0.5
  @State private var opacity = 0.0
  @State private var rotation = -30.0
  @State private var showStars = false

  private func handleCompletion() {
    if let token = appState.jwtToken {
      APIManager.shared.fetchProfileData(token: token, forceRefresh: true) { _ in
        DispatchQueue.main.async {
          appState.showPaywall = false
          dismiss()
        }
      }
    } else {
      appState.showPaywall = false
      dismiss()
    }
    if appState.showProfile {
      appState.showProfile = false
    }
  }

  var body: some View {
    ZStack {
      ColorTheme.black.opacity(0.95)
        .edgesIgnoringSafeArea(.all)

      // Floating stars background
      ForEach(0..<15) { index in
        Image(systemName: "star.fill")
          .font(.system(size: CGFloat.random(in: 10...20)))
          .foregroundColor(ColorTheme.primary.opacity(0.3))
          .offset(
            x: CGFloat.random(in: -180...180),
            y: CGFloat.random(in: -300...300)
          )
          .opacity(showStars ? 0.8 : 0)
          .animation(
            .easeInOut(duration: 1.2)
              .repeatForever()
              .delay(Double.random(in: 0...0.5)),
            value: showStars
          )
      }

      VStack(spacing: 24) {
        Spacer()

        Image(systemName: "star.fill")
          .font(.system(size: 80))
          .foregroundColor(ColorTheme.primary)
          .rotationEffect(.degrees(rotation))
          .scaleEffect(scale)
          .opacity(opacity)

        Text("Welcome to Premium!")
          .font(.system(size: 32, weight: .bold))
          .foregroundColor(ColorTheme.white)
          .scaleEffect(scale)
          .opacity(opacity)

        Text("Thank you for your support")
          .font(.system(size: 18))
          .foregroundColor(ColorTheme.lightGrey)
          .scaleEffect(scale)
          .opacity(opacity)

        Spacer()

        Button(action: handleCompletion) {
          Text("Let's Go!")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(ColorTheme.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ColorTheme.primary)
            .cornerRadius(12)
        }
        .padding(.horizontal, 32)
        .opacity(opacity)
      }
      .padding(.vertical, 40)
    }
    .onAppear {
      withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
        scale = 1
        opacity = 1
        rotation = 360 * 2  // Two full spins
      }
      withAnimation(.easeInOut(duration: 0.3)) {
        showStars = true
      }
    }
  }
}
