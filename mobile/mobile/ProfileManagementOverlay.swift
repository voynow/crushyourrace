import SwiftUI

struct ProfileManagementOverlay: View {
  @Binding var isPresented: Bool
  @EnvironmentObject var appState: AppState
  let profileData: ProfileData

  @State private var showDeleteConfirmation: Bool = false
  @State private var showSignOutConfirmation: Bool = false
  @State private var isProcessing: Bool = false
  @State private var showOnboarding: Bool = false
  @State private var showSubscriptionManagement: Bool = false
  @State private var showUpgradeManagement: Bool = false

  @StateObject private var storeKit = StoreKitManager()
  @State private var isLoading = false
  @State private var showError = false
  @State private var errorMessage = ""
  @State private var showSuccessAnimation = false

  var body: some View {
    ZStack {
      // Semi-transparent background
      ColorTheme.black.opacity(0.9)
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 12) {
        // Header with close button
        HStack {
          Text("Account Settings")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(ColorTheme.white)
          Spacer()
          Button(action: { isPresented = false }) {
            Image(systemName: "xmark")
              .foregroundColor(ColorTheme.lightGrey)
              .font(.system(size: 20))
          }
        }

        // Profile Header Section
        VStack(spacing: 24) {
          AsyncImage(url: URL(string: profileData.profile)) { phase in
            switch phase {
            case .empty:
              Circle()
                .fill(ColorTheme.darkDarkGrey)
                .overlay(
                  Image(systemName: "person.fill")
                    .foregroundColor(ColorTheme.midLightGrey)
                    .font(.system(size: 40))
                )
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            case .failure:
              Circle()
                .fill(ColorTheme.darkDarkGrey)
                .overlay(
                  Image(systemName: "person.fill")
                    .foregroundColor(ColorTheme.midLightGrey)
                    .font(.system(size: 40))
                )
            @unknown default:
              EmptyView()
            }
          }
          .frame(width: 120, height: 120)
          .clipShape(Circle())
          .overlay(Circle().stroke(ColorTheme.primary, lineWidth: 2))

          VStack(spacing: 12) {

            VStack(spacing: 4) {
              Text("\(profileData.firstname) \(profileData.lastname)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ColorTheme.white)

              if let email = profileData.email {
                Text(email)
                  .font(.system(size: 16))
                  .foregroundColor(ColorTheme.lightGrey)
              }
            }

            HStack(spacing: 8) {
              Image(systemName: "calendar")
                .foregroundColor(ColorTheme.primary)
              Text("Member since \(profileData.memberSince)")
                .font(.system(size: 16))
                .foregroundColor(ColorTheme.lightGrey)
            }
          }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 36)
        .frame(maxWidth: .infinity)
        .background(ColorTheme.darkDarkGrey)
        .cornerRadius(20)

        // Membership Status
        membershipCard

        managementButton(
          title: "Sign Out",
          icon: "rectangle.portrait.and.arrow.right",
          color: ColorTheme.primary,
          action: { showSignOutConfirmation = true }
        )

        managementButton(
          title: "Delete Account",
          icon: "trash",
          color: ColorTheme.redPink,
          action: { showDeleteConfirmation = true }
        )

        Button(action: handleAbout) {
          HStack(spacing: 4) {
            Text("About")
              .font(.system(size: 16, weight: .light))
              .foregroundColor(ColorTheme.lightGrey)
            Text("Crush Your Race")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(ColorTheme.lightGrey)
          }
        }
        .padding(.top, 8)

        Spacer()
      }
      .padding(24)
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      if showSubscriptionManagement {
        subscriptionManagementOverlay
      }

      if showUpgradeManagement {
        upgradeManagementOverlay
      }

      if showSuccessAnimation {
        PremiumSuccessAnimation()
      }
    }
    .confirmationDialog(
      "Delete Account?",
      isPresented: $showDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Delete", role: .destructive, action: handleAccountDeletion)
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This action cannot be undone. All your data will be permanently deleted.")
    }
    .confirmationDialog(
      "Sign Out?",
      isPresented: $showSignOutConfirmation,
      titleVisibility: .visible
    ) {
      Button("Sign Out", role: .destructive, action: handleSignOut)
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Are you sure you want to sign out?")
    }
    .fullScreenCover(isPresented: $showOnboarding) {
      OnboardingCarousel(showCloseButton: true)
    }
    .alert("Error", isPresented: $showError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }

  private var membershipCard: some View {
    Button(action: handleSubscription) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Image(systemName: profileData.isPremium ? "crown.fill" : "person.fill")
            .foregroundColor(profileData.isPremium ? ColorTheme.green : ColorTheme.primaryLight)
          Text(profileData.isPremium ? "Premium Member" : "Free Tier")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(profileData.isPremium ? ColorTheme.green : ColorTheme.primaryLight)
          Spacer()
          Image(systemName: "chevron.right")
            .foregroundColor(profileData.isPremium ? ColorTheme.green : ColorTheme.primaryLight)
        }

        if profileData.isPremium {
          Text("Your premium membership is active")
            .font(.system(size: 14))
            .foregroundColor(ColorTheme.lightGrey)
        } else {
          Text("Sign up for premium to get unlimited access!")
            .font(.system(size: 14))
            .foregroundColor(ColorTheme.lightGrey)
        }
      }
      .padding(16)
      .background(ColorTheme.darkDarkGrey)
      .cornerRadius(12)
    }
  }

  private func managementButton(
    title: String,
    icon: String,
    color: Color = ColorTheme.primary,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack {
        Image(systemName: icon)
        Text(title)
        Spacer()
        Image(systemName: "chevron.right")
      }
      .foregroundColor(color)
      .padding(16)
      .background(ColorTheme.darkDarkGrey)
      .cornerRadius(12)
    }
  }

  private func handleSubscription() {
    if profileData.isPremium {
      showSubscriptionManagement = true
    } else {
      showUpgradeManagement = true
    }
  }

  private func handleAccountDeletion() {
    guard let token = appState.jwtToken else { return }
    isProcessing = true

    // TODO: Implement actual API call
    // APIManager.shared.deleteAccount(token: token) { result in
    //     DispatchQueue.main.async {
    //         isProcessing = false
    //         if case .success = result {
    //             appState.status = .loggedOut
    //             appState.jwtToken = nil
    //             UserDefaults.standard.removeObject(forKey: "jwt_token")
    //         }
    //     }
    // }
  }

  private func handleSignOut() {
    appState.status = .loggedOut
    appState.jwtToken = nil
    UserDefaults.standard.removeObject(forKey: "jwt_token")
    isPresented = false
  }

  private func handleAbout() {
    showOnboarding = true
  }

  private var subscriptionManagementOverlay: some View {
    ZStack {
      ColorTheme.black.opacity(0.9)
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 32) {
        // Premium Crown Icon
        Image(systemName: "crown.fill")
          .font(.system(size: 44))
          .foregroundColor(ColorTheme.green)
          .padding(.top, 8)

        VStack(spacing: 16) {
          Text("Premium Membership")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(ColorTheme.white)

          VStack(spacing: 24) {
            Text(
              "As a premium member, you're part of an elite community of dedicated athletes. Your feedback directly shapes the future of Crush Your Race."
            )
            .font(.system(size: 16))
            .foregroundColor(ColorTheme.lightGrey)
            .multilineTextAlignment(.center)

            Text(
              "You have priority access to me (Jamie) at voynow99@gmail.com. Please reach out before making any changes to your subscription - I'd love to hear from you!"
            )
            .font(.system(size: 16))
            .foregroundColor(ColorTheme.lightGrey)
            .multilineTextAlignment(.center)
          }
        }
        .padding(.horizontal)

        VStack(spacing: 16) {
          Button(action: {
            if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
              UIApplication.shared.open(url)
            }
            showSubscriptionManagement = false
          }) {
            HStack {
              Text("Manage Subscription")
                .padding(.horizontal, 4)
              Spacer()
              Image(systemName: "chevron.right")
            }
            .foregroundColor(ColorTheme.primary)
            .padding(16)
            .background(ColorTheme.darkGrey)
            .cornerRadius(12)
          }

          Button(action: { showSubscriptionManagement = false }) {
            Text("Close")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(ColorTheme.lightGrey)
              .padding(.vertical, 8)
          }
        }
        .padding(.horizontal)
      }
      .padding(32)
      .background(ColorTheme.darkDarkGrey)
      .cornerRadius(20)
      .padding(24)
    }
  }

  private var upgradeManagementOverlay: some View {
    ZStack {
      ColorTheme.black.opacity(0.9)
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 32) {
        // Premium Crown Icon
        Image(systemName: "crown.fill")
          .font(.system(size: 44))
          .foregroundColor(ColorTheme.primary)
          .padding(.top, 8)

        VStack(spacing: 20) {
          Text("Unlock Premium")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(ColorTheme.white)

          Text("Join our elite community of dedicated athletes")
            .font(.system(size: 16))
            .foregroundColor(ColorTheme.lightGrey)
            .multilineTextAlignment(.center)
        }

        // Pricing Section
        PricingSection()

        // Benefits Section
        PremiumBenefits()

        Spacer()

        // Action Buttons
        VStack(spacing: 16) {
          Button(action: {
            handlePurchase()
          }) {
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
            .cornerRadius(8)
          }
          .disabled(isLoading)

          Button(action: { showUpgradeManagement = false }) {
            Text("Maybe Later")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(ColorTheme.lightGrey)
          }
        }
        .padding(.horizontal, 36)
      }
      .padding(24)
      .background(ColorTheme.darkDarkGrey)
      .cornerRadius(20)
      .padding(12)
    }
  }

  private func handlePurchase() {
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
          errorMessage = error.localizedDescription
          showError = true
          isLoading = false
        }
      }
    }
  }
}
