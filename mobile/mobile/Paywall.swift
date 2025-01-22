import SwiftUI

struct PaywallView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @State private var isLoading = false
  @State private var showError = false
  @State private var errorMessage = ""
  @StateObject private var storeKit = StoreKitManager()
  @State private var showSuccessAnimation = false

  var body: some View {
    ZStack {
      ColorTheme.black.edgesIgnoringSafeArea(.all)

      ScrollView {
        VStack(spacing: 40) {
          VStack(spacing: 20) {
            Text("Your Trial Has Ended")
              .font(.system(size: 20, weight: .bold))
              .foregroundColor(ColorTheme.white)
              .padding(.top, 10)

            Text(
              "It costs us money to keep the lights on. Upgrade to Premium to continue training with us."
            )
            .font(.system(size: 14))
            .foregroundColor(ColorTheme.lightGrey)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 24)
          }

          PricingSection()
          PremiumBenefits()

          Button(action: handleSubscribe) {
            HStack {
              if isLoading {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle(tint: .white))
                  .scaleEffect(0.8)
              }
              Image(systemName: "star.fill")
              Text(isLoading ? "Processing..." : "Get Premium")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(ColorTheme.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ColorTheme.primary)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(ColorTheme.primary.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(8)
          }
          .disabled(isLoading)
          .padding(.horizontal, 36)
          .padding(.bottom, 16)
          .background(ColorTheme.black)
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
      }

      if showSuccessAnimation {
        PremiumSuccessAnimation()
      }
    }
    .alert("Error", isPresented: $showError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }

  private func handleSubscribe() {
    isLoading = true

    Task {
      do {
        try await storeKit.purchase {
          withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showSuccessAnimation = true
          }
        }
        await MainActor.run {
          isLoading = false
        }
      } catch {
        await MainActor.run {
          showError(message: error.localizedDescription)
        }
      }
    }
  }

  private func showError(message: String) {
    errorMessage = message
    showError = true
    isLoading = false
  }

}

struct SuccessAnimation: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @State private var scale = 0.5
  @State private var opacity = 0.0
  @State private var rotation = -30.0
  @State private var showStars = false

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

        Button(action: {
          appState.showPaywall = false
          dismiss()
        }) {
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

#Preview("Paywall") {
  PaywallView()
    .environmentObject(AppState())
}
