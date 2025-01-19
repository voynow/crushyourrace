import SwiftUI

struct PaywallView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @State private var isLoading = false
  @State private var showError = false
  @State private var errorMessage = ""
  @StateObject private var storeKit = StoreKitManager()

  var body: some View {
    ZStack {
      ColorTheme.black.edgesIgnoringSafeArea(.all)

      VStack(spacing: 40) {

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
      }
    }
    .alert("Error", isPresented: $showError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
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
    }
    .frame(maxWidth: 300, alignment: .leading)
  }

  private func handleSubscribe() {
    isLoading = true

    Task {
      do {
        try await storeKit.purchase()
        await MainActor.run {
          isLoading = false
          dismiss()
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

#Preview("Paywall") {
  PaywallView()
    .environmentObject(AppState())
}
