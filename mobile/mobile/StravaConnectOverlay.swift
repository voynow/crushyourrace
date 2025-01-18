import SwiftUI

struct StravaConnectOverlay: View {
  @EnvironmentObject var appState: AppState
  @State private var showOnboarding: Bool = false
  @State private var showDeleteConfirmation: Bool = false

  var body: some View {
    Color.clear
      .overlay(
        GeometryReader { geometry in
          VStack(spacing: 16) {
            HStack {
              Text("Connect with Strava")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ColorTheme.white)
              Image("stravaIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 20)
            }

            VStack(spacing: 24) {
              Text("Log in with Strava to unlock the full experience")
                .font(.system(size: 16))
                .foregroundColor(ColorTheme.white)
                .multilineTextAlignment(.center)

              Text(
                "While we're expanding to support more platforms, Strava integration currently offers the most complete feature set."
              )
              .font(.system(size: 14))
              .foregroundColor(ColorTheme.lightGrey)
              .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Divider()
              .background(ColorTheme.darkGrey)
              .padding(.vertical, 8)

            HStack(spacing: 12) {
              Button(action: { showOnboarding = true }) {
                HStack {
                  Image(systemName: "info.circle")
                  Text("About")
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

              Button(action: {
                appState.clearAuthState()
              }) {
                HStack {
                  Image(systemName: "rectangle.portrait.and.arrow.right")
                  Text("Sign Out")
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
            }
            .padding(.horizontal, 24)

            Button(action: {
              showDeleteConfirmation = true
            }) {
              Text("Delete Account")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(ColorTheme.lightGrey)
                .padding(.vertical, 12)
                .padding(.horizontal, 18)
                .background(ColorTheme.darkGrey)
                .cornerRadius(8)
            }
            .padding(.top, 8)
            .confirmationDialog(
              "Delete Account?",
              isPresented: $showDeleteConfirmation,
              titleVisibility: .visible
            ) {
              Button("Delete", role: .destructive) {
                appState.clearAuthState()  // Sign out first
                // TODO: Add actual account deletion logic here
              }
              Button("Cancel", role: .cancel) {}
            } message: {
              Text("This action cannot be undone. All your data will be permanently deleted.")
            }
          }
          .padding(.vertical, 24)
          .padding(.horizontal, 16)
          .background(ColorTheme.darkGrey.opacity(0.95))
          .cornerRadius(16)
          .shadow(color: Color.black.opacity(0.2), radius: 20)
          .frame(maxWidth: .infinity)
          .position(
            x: geometry.size.width / 2,
            y: 200
          )
        }
      )
      .ignoresSafeArea()
      .fullScreenCover(isPresented: $showOnboarding) {
        OnboardingCarousel(showCloseButton: true)
      }
  }
}

#Preview {
  StravaConnectOverlay()
}
