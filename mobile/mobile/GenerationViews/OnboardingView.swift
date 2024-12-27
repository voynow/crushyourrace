import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject var appState: AppState
  @StateObject private var viewModel: OnboardingViewModel

  init() {
    let vm = OnboardingViewModel()
    _viewModel = StateObject(wrappedValue: vm)
  }

  var body: some View {
    ZStack {
      ColorTheme.black.edgesIgnoringSafeArea(.all)

      if !viewModel.hasSubmittedEmail {
        EmailSetupView(
          email: $viewModel.email,
          onSubmit: viewModel.handleEmailSubmission
        )
      } else if viewModel.showRaceSetup {
        RaceSetupPromptView(
          onSkip: { viewModel.completeOnboarding(skipRaceSetup: true) },
          onSetupRace: { viewModel.showRaceSetupSheet = true }
        )
        .sheet(isPresented: $viewModel.showRaceSetupSheet) {
          RaceSetupSheet(
            preferences: $viewModel.preferences,
            isPresented: $viewModel.showRaceSetupSheet,
            onSave: viewModel.savePreferencesAndCompleteOnboarding
          )
        }
      } else if viewModel.isGenerating {
        GenerationProgressView()
      }
    }
    .alert("Error", isPresented: $viewModel.showError) {
      Button("OK") {}
    } message: {
      Text(viewModel.errorMessage ?? "An error occurred")
    }
    .onAppear {
      viewModel.appState = appState
    }
  }
}

private struct EmailSetupView: View {
  @Binding var email: String
  let onSubmit: (String) -> Void

  var body: some View {
    OnboardingEmailView(email: $email, onSubmit: onSubmit)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(ColorTheme.black.opacity(0.95).edgesIgnoringSafeArea(.all))
      .zIndex(1)
  }
}

private struct RaceSetupPromptView: View {
  let onSkip: () -> Void
  let onSetupRace: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Text("Would you like to set up your race details now?")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(ColorTheme.white)
        .multilineTextAlignment(.center)

      Text("You can always do this later in your profile")
        .font(.system(size: 16))
        .foregroundColor(ColorTheme.lightGrey)
        .multilineTextAlignment(.center)

      HStack(spacing: 16) {
        Button(action: onSkip) {
          Text("Skip for Now")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(ColorTheme.lightGrey)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ColorTheme.darkDarkGrey)
            .cornerRadius(8)
        }

        Button(action: onSetupRace) {
          Text("Set Up Race")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(ColorTheme.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ColorTheme.primary)
            .cornerRadius(8)
        }
      }
      .padding(.horizontal, 24)
    }
    .padding(32)
    .background(ColorTheme.darkDarkGrey)
    .cornerRadius(20)
    .padding(.horizontal, 24)
  }
}

private struct GenerationProgressView: View {
  var body: some View {
    WaitingForGenerationView()
  }
}

final class OnboardingViewModel: ObservableObject {
  @Published var email: String = ""
  @Published var hasSubmittedEmail = false
  @Published var showRaceSetup = false
  @Published var showRaceSetupSheet = false
  @Published var preferences = Preferences()
  @Published var isGenerating = false
  @Published var errorMessage: String?
  @Published var showError = false

  var appState: AppState?

  func handleEmailSubmission(_ email: String) {
    guard let token = appState?.jwtToken else {
      showError(message: "No token found")
      return
    }

    APIManager.shared.updateEmail(token: token, email: email) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success:
          self?.email = email
          self?.hasSubmittedEmail = true
          self?.showRaceSetup = true
        case .failure(let error):
          self?.showError(message: "Failed to update email: \(error.localizedDescription)")
        }
      }
    }
  }

  func savePreferencesAndCompleteOnboarding() {
    showRaceSetup = false
    isGenerating = true
    completeOnboarding(skipRaceSetup: false)
  }

  func completeOnboarding(skipRaceSetup: Bool) {
    guard let token = appState?.jwtToken else {
      showError(message: "No token found")
      return
    }

    if skipRaceSetup {
      showRaceSetup = false
      isGenerating = true
    }

    refreshUserAndComplete(token: token)
  }

  private func refreshUserAndComplete(token: String) {
    APIManager.shared.refreshUser(token: token) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success:
          self?.appState?.status = .loggedIn
        case .failure(let error):
          print("Refresh user error details: \(error)")
          self?.showError(message: "Failed to complete setup: \(error.localizedDescription)")
        }
      }
    }
  }

  private func showError(message: String) {
    errorMessage = message
    showError = true
  }
}
