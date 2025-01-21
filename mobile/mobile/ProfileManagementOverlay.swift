import SwiftUI

struct ProfileManagementOverlay: View {
  @Binding var isPresented: Bool
  @EnvironmentObject var appState: AppState
  let profileData: ProfileData

  @State private var showDeleteConfirmation: Bool = false
  @State private var isProcessing: Bool = false
  @State private var showOnboarding: Bool = false

  var body: some View {
    ZStack {
      // Semi-transparent background
      ColorTheme.black.opacity(0.9)
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 32) {
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

        // Management Options
        VStack(spacing: 16) {
          managementButton(
            title: "About Crush Your Race",
            icon: "info.circle",
            color: ColorTheme.midLightGrey,
            action: handleAbout
          )

          managementButton(
            title: "Sign Out",
            icon: "rectangle.portrait.and.arrow.right",
            color: ColorTheme.primaryDark,
            action: handleSignOut
          )

          managementButton(
            title: "Delete Account",
            icon: "trash",
            color: ColorTheme.redPink,
            action: { showDeleteConfirmation = true }
          )
        }

        Spacer()
      }
      .padding(24)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    .fullScreenCover(isPresented: $showOnboarding) {
      OnboardingCarousel(showCloseButton: true)
    }
  }

  private var membershipCard: some View {
    Button(action: handleSubscription) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Image(systemName: profileData.isPremium ? "crown.fill" : "person.fill")
            .foregroundColor(profileData.isPremium ? ColorTheme.green : ColorTheme.lightGrey)
          Text(profileData.isPremium ? "Premium Member" : "Free Tier")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(profileData.isPremium ? ColorTheme.green : ColorTheme.lightGrey)
          Spacer()
          Image(systemName: "chevron.right")
            .foregroundColor(ColorTheme.midLightGrey)
        }

        if profileData.isPremium {
          Text("Your premium membership is active")
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
    // TODO: Implement subscription management
    if profileData.isPremium {
      // Open subscription management
    } else {
      // Open upgrade flow
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
}
