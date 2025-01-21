import SwiftUI

struct ProfileView: View {
  @Binding var isPresented: Bool
  @Binding var showProfile: Bool
  @State private var profileData: ProfileData?
  @EnvironmentObject var appState: AppState
  @State private var isSaving: Bool = false
  @State private var isLoading: Bool = true

  var body: some View {
    ZStack {
      ColorTheme.black.edgesIgnoringSafeArea(.all)

      VStack {
        HStack {
          Button(action: {
            isPresented = false
            showProfile = false
          }) {
            Text("Crush ")
              .font(.system(size: 28, weight: .black))
              .foregroundColor(ColorTheme.primaryLight)
              + Text("Your Race")
              .font(.system(size: 28, weight: .black))
              .foregroundColor(ColorTheme.primary)
          }
          .buttonStyle(PlainButtonStyle())

          Spacer()

          Button(action: {
            isPresented = false
            showProfile = false
          }) {
            Image(systemName: "xmark")
              .foregroundColor(ColorTheme.lightGrey)
              .font(.system(size: 20, weight: .semibold))
          }
          .padding(.trailing, 12)
        }
        .padding(.horizontal)
        .padding(.top, 5)
        .background(ColorTheme.black)
        .zIndex(1)

        if appState.authStrategy == .apple {
          VStack(spacing: 16) {
            ProfileSkeletonView()
              .overlay(StravaConnectOverlay())
          }
        } else if isLoading {
          ProfileSkeletonView()
        } else {
          VStack(spacing: 24) {
            if let profileData = profileData {
              ScrollView {
                VStack(spacing: 24) {
                  ProfileInfoCard(profileData: profileData)
                  PreferencesContainer(preferences: preferencesBinding)
                }
                .padding()
              }
            } else {
              VStack {
                Text("Failed to load profile")
                  .foregroundColor(ColorTheme.lightGrey)
              }
              .frame(maxHeight: .infinity)
            }
          }
        }
      }
    }
    .onAppear {
      fetchProfileDataHelper()
    }
  }

  private func handleSignOut() {
    appState.status = .loggedOut
    appState.jwtToken = nil
    UserDefaults.standard.removeObject(forKey: "jwt_token")
    isPresented = false
  }

  private var preferencesBinding: Binding<Preferences> {
    Binding(
      get: {
        if let preferencesString = profileData?.preferences {
          if let jsonData = preferencesString.data(using: .utf8) {
            do {
              let decoder = JSONDecoder()
              decoder.dateDecodingStrategy = .iso8601
              let prefs = try decoder.decode(Preferences.self, from: jsonData)
              return prefs
            } catch {
              assertionFailure("Failed to decode preferences: \(error)")
              return Preferences()
            }
          }
        }
        return Preferences()
      },
      set: { newValue in
        do {
          let encoder = JSONEncoder()
          encoder.dateEncodingStrategy = .iso8601
          encoder.outputFormatting = .prettyPrinted

          let preferencesJSON = try encoder.encode(newValue)
          if let preferencesString = String(data: preferencesJSON, encoding: .utf8) {
            profileData?.preferences = preferencesString
          }
        } catch {
          assertionFailure("Failed to encode preferences: \(error)")
          if let emptyPrefs = try? JSONEncoder().encode(Preferences()),
            let emptyPrefsString = String(data: emptyPrefs, encoding: .utf8)
          {
            profileData?.preferences = emptyPrefsString
          }
        }
      }
    )
  }

  private func fetchProfileDataHelper() {
    guard let token = appState.jwtToken else {
      isLoading = false
      return
    }

    APIManager.shared.fetchProfileData(token: token) { result in
      DispatchQueue.main.async {
        self.isLoading = false
        if case .success(let profile) = result {
          self.profileData = profile
        }
      }
    }
  }
}

struct ProfileInfoCard: View {
  let profileData: ProfileData
  @State private var showManagementOverlay: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Button(action: { showManagementOverlay = true }) {
        HStack(spacing: 16) {
          VStack {
            AsyncImage(url: URL(string: profileData.profile)) { phase in
              switch phase {
              case .empty:
                LoadingIcon()
              case .success(let image):
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
              case .failure:
                Image(systemName: "person.fill")
                  .foregroundColor(ColorTheme.midLightGrey)
              @unknown default:
                EmptyView()
              }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(Circle().stroke(ColorTheme.primary, lineWidth: 2))
          }
          Spacer()
          VStack(alignment: .leading, spacing: 4) {
            Text("\(profileData.firstname) \(profileData.lastname)")
              .font(.system(size: 24, weight: .bold))
              .foregroundColor(ColorTheme.white)
              .padding(.bottom, 8)

            if let email = profileData.email {
              Text(email)
                .font(.system(size: 14))
                .foregroundColor(ColorTheme.lightGrey)
            } else {
              Text("Missing email address")
                .font(.system(size: 14))
                .foregroundColor(ColorTheme.lightGrey)
            }
            Text("Member since \(profileData.memberSince)")
              .font(.system(size: 14))
              .foregroundColor(ColorTheme.lightGrey)
              .padding(.bottom, 8)

            if profileData.isPremium {
              HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                Text("Premium Member")
              }
              .font(.system(size: 14))
              .foregroundColor(ColorTheme.green)
            } else {
              HStack(spacing: 4) {
                Image(systemName: "star")
                Text("Free Tier")
              }
              .font(.system(size: 14))
              .foregroundColor(ColorTheme.lightGrey)
            }
          }
        }
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding(.vertical, 24)
    .padding(.horizontal, 36)
    .frame(maxWidth: .infinity)
    .background(ColorTheme.darkDarkGrey)
    .cornerRadius(20)
    .fullScreenCover(isPresented: $showManagementOverlay) {
      ProfileManagementOverlay(
        isPresented: $showManagementOverlay,
        profileData: profileData
      )
    }
  }

  private var formattedJoinDate: String {
    "Sept '24"
  }
}

struct LoadingIcon: View {
  var body: some View {
    Circle()
      .fill(ColorTheme.darkDarkGrey)
      .overlay(
        Image(systemName: "person.fill")
          .foregroundColor(ColorTheme.midLightGrey)
      )
      .frame(width: 50, height: 50)
  }
}
