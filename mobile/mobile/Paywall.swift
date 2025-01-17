import SwiftUI

struct PaywallView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @State private var isLoading = false
  @State private var showError = false
  @State private var errorMessage = ""
  @State private var showSkipConfirmation = false

  var body: some View {
    ZStack {
      ColorTheme.black.edgesIgnoringSafeArea(.all)

      VStack(spacing: 40) {

        VStack(spacing: 10) {
          HStack {
            Text("Crush")
              .font(.system(size: 36, weight: .black))
              .foregroundColor(ColorTheme.primaryLight)

            Text("Your Race")
              .font(.system(size: 36, weight: .black))
              .foregroundColor(ColorTheme.primary)
          }
          .padding(.top, 40)

          Text("Your Free Trial Has Ended")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(ColorTheme.white)
        }

        Text(
          "It costs us money to keep the lights on. Upgrade to Premium to continue training with us."
        )
        .font(.system(size: 14))
        .foregroundColor(ColorTheme.lightGrey)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 24)

        VStack(spacing: 20) {
          Text("Launch Price!")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(ColorTheme.primary)

          HStack(alignment: .firstTextBaseline, spacing: 8) {
            ZStack(alignment: .center) {
              Text("$10")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(ColorTheme.midDarkGrey)

              Rectangle()
                .frame(width: 110, height: 4)
                .foregroundColor(ColorTheme.midDarkGrey)
                .rotationEffect(.degrees(165))
            }
            .frame(height: 48)

            Text("$5")
              .font(.system(size: 48, weight: .bold))
              .foregroundColor(ColorTheme.white)

            Text("per month")
              .font(.system(size: 18))
              .foregroundColor(ColorTheme.midLightGrey)
          }

          Text("50% OFF")
            .font(.system(size: 13, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(ColorTheme.redPink.opacity(0.15))
            .foregroundColor(ColorTheme.redPink)
            .cornerRadius(6)
            .padding(.bottom, 4)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(ColorTheme.darkDarkGrey)
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.primary.opacity(0.2), lineWidth: 1)
            )
        )
        .padding(.horizontal, 24)

        VStack(spacing: 24) {
          premiumBenefit(
            icon: "person.2.fill",
            title: "Collaborate with the team",
            subtitle: "You will shape the future of the platform"
          )

          premiumBenefit(
            icon: "chart.line.uptrend.xyaxis",
            title: "Be on the cutting edge",
            subtitle: "The next generation of running is here"
          )

          premiumBenefit(
            icon: "heart.fill",
            title: "Support the development",
            subtitle: "Your support is invaluable to our team"
          )
        }
        .padding(.horizontal, 24)

        Spacer()

        HStack(spacing: 16) {
          Button(action: { showSkipConfirmation = true }) {
            HStack {
              Image(systemName: "xmark.circle")
              Text("Skip for Now")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(ColorTheme.lightGrey)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ColorTheme.darkDarkGrey)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(ColorTheme.midDarkGrey, lineWidth: 1)
            )
            .cornerRadius(8)
          }

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
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
      }
      .overlay(
        Group {
          if showSkipConfirmation {
            skipConfirmationOverlay
              .transition(.opacity)
          }
        }
      )
    }
  }

  private func premiumBenefit(icon: String, title: String, subtitle: String) -> some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.system(size: 24))
        .foregroundColor(ColorTheme.primary)
        .frame(width: 32)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(ColorTheme.white)
        Text(subtitle)
          .font(.system(size: 15))
          .foregroundColor(ColorTheme.lightGrey)
      }

      Spacer()
    }
  }

  private func handleSubscribe() {
    isLoading = true

    guard let token = appState.jwtToken else {
      showError(message: "Authentication error. Please try again.")
      return
    }

    // TODO: Implement RevenueCat or StoreKit subscription logic here
    // APIManager.shared.updatePremiumStatus(token: token) { result in
    //   DispatchQueue.main.async {
    //     isLoading = false

    //     switch result {
    //     case .success:
    //       dismiss()
    //     case .failure(let error):
    //       showError(message: error.localizedDescription)
    //     }
    //   }
    // }
  }

  private func handleSkip() {
    guard let token = appState.jwtToken else {
      showError(message: "Authentication error. Please try again.")
      return
    }

    // APIManager.shared.updatePaywallStatus(token: token, paywall: true) { result in
    //   DispatchQueue.main.async {
    //     switch result {
    //     case .success:
    //       dismiss()
    //     case .failure(let error):
    //       showError(message: error.localizedDescription)
    //     }
    //   }
    // }
  }

  private func showError(message: String) {
    errorMessage = message
    showError = true
    isLoading = false
  }

  private var skipConfirmationOverlay: some View {
    ZStack {
      Color.black.opacity(0.8)
        .edgesIgnoringSafeArea(.all)
        .transition(.opacity)

      VStack(spacing: 24) {
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.circle.fill")
            .font(.system(size: 36))
            .foregroundColor(ColorTheme.primary)

          Text("Are you sure?")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(ColorTheme.white)

          Text(
            "Your free trial has ended. Your training plans will no longer update automatically."
          )
          .font(.system(size: 16))
          .foregroundColor(ColorTheme.lightGrey)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 24)
        }

        HStack(spacing: 12) {
          Button(action: { showSkipConfirmation = false }) {
            HStack {
              Image(systemName: "arrow.left")
              Text("Go Back")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(ColorTheme.primaryDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ColorTheme.darkDarkGrey)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(ColorTheme.primaryDark, lineWidth: 1)
            )
            .cornerRadius(8)
          }

          Button(action: handleSkip) {
            HStack {
              Text("Yes, Skip")
              Image(systemName: "arrow.right")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(ColorTheme.lightGrey)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ColorTheme.darkDarkGrey)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(ColorTheme.midDarkGrey, lineWidth: 1)
            )
            .cornerRadius(8)
          }
        }
        .padding(.horizontal, 24)
      }
      .padding(.vertical, 24)
      .padding(.horizontal, 16)
      .background(ColorTheme.darkGrey.opacity(0.95))
      .cornerRadius(16)
      .shadow(color: Color.black.opacity(0.2), radius: 20)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(32)
    }
  }
}

#Preview("Paywall") {
  PaywallView()
    .environmentObject(AppState())
}
