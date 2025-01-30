import SwiftUI

struct DashboardView: View {
  @EnvironmentObject var appState: AppState
  @State private var trainingWeekData: FullTrainingWeek?
  @State private var weeklySummaries: [WeekSummary]?
  @State private var isLoadingTrainingWeek = true
  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""
  @State private var selectedTab: Int = 0
  @State private var trainingPlan: TrainingPlan?
  @State private var showRaceSetupSheet: Bool = false
  @State private var preferences = Preferences()

  var body: some View {
    ZStack {
      ColorTheme.black.edgesIgnoringSafeArea(.all)

      TabView(selection: $appState.selectedTab) {
        VStack {
          DashboardNavbar(
            onLogout: { appState.clearAuthState() }, showProfile: $appState.showProfile
          )
          .background(ColorTheme.black)
          .zIndex(1)

          ScrollView {
            if appState.showPaywall {
              VStack(spacing: 16) {
                PaywallView()
                  .padding(.top, 16)
              }
              .transition(
                .opacity
                  .combined(with: .scale(scale: 0.95))
                  .animation(.spring(response: 0.4, dampingFraction: 0.8))
              )
            } else if appState.authStrategy == .apple {
              VStack(spacing: 16) {
                DashboardSkeletonView()
                  .overlay(StravaConnectOverlay())
              }
            } else if let data = trainingWeekData {
              TrainingWeekView(
                trainingWeekData: data,
                weeklySummaries: weeklySummaries
              )
            } else if isLoadingTrainingWeek {
              DashboardSkeletonView()
            } else {
              VStack(spacing: 16) {
                Text("Let's get you started!")
                  .font(.title3)
                  .foregroundColor(ColorTheme.lightGrey)
                Text("Set up your race details to see your training week.")
                  .font(.subheadline)
                  .foregroundColor(ColorTheme.midLightGrey)
                  .multilineTextAlignment(.center)
                  .padding(.horizontal)
                Button(action: {
                  showRaceSetupSheet = true
                }) {
                  Text("Set Up Race Details")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ColorTheme.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(ColorTheme.primary)
                    .cornerRadius(8)
                }
              }
              .padding()
              .background(ColorTheme.darkDarkGrey)
              .cornerRadius(12)
              .frame(maxHeight: .infinity, alignment: .center)
              .padding()
            }
          }
          .refreshable {
            if appState.authStrategy != .apple {
              fetchData()
            }
          }
        }
        .background(ColorTheme.black.edgesIgnoringSafeArea(.all))
        .tabItem {
          Image(systemName: "calendar")
          Text("Training Week")
        }
        .tag(0)
        TrainingPlanView(
          historicalWeeks: weeklySummaries ?? [],
          preloadedPlan: trainingPlan
        )
        .tabItem {
          Image(systemName: "chart.bar.fill")
          Text("Training Plan")
        }
        .tag(1)
      }
      .accentColor(ColorTheme.primary)
      .onAppear {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ColorTheme.black)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(ColorTheme.lightGrey)
      }
    }
    .navigationBarHidden(true)
    .onAppear {
      fetchData()
      if appState.notificationStatus == .notDetermined {
        appState.requestNotificationPermission()
      }
    }
    .alert(isPresented: $showErrorAlert) {
      Alert(
        title: Text("Error"),
        message: Text(errorMessage),
        dismissButton: .default(Text("OK"))
      )
    }
    .sheet(isPresented: $showRaceSetupSheet) {
      RaceSetupSheet(
        preferences: $preferences,
        isPresented: $showRaceSetupSheet,
        onSave: {
          fetchData()
          appState.setGeneratingPlanState()
        }
      )
    }
  }

  private func fetchData() {
    if appState.authStrategy == .apple {
      return
    }

    isLoadingTrainingWeek = true
    // First fetch training week data
    fetchTrainingWeekData {
      isLoadingTrainingWeek = false

      // Then fetch the rest with a slight delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        fetchWeeklySummaries {}

        if let token = appState.jwtToken {
          APIManager.shared.fetchProfileData(token: token) { result in
            if case .failure(let error) = result {
              print("Error pre-fetching profile: \(error)")
            }
          }

          APIManager.shared.fetchTrainingPlan(token: token) { result in
            DispatchQueue.main.async {
              if case .success(let plan) = result {
                self.trainingPlan = plan
              } else if case .failure(let error) = result {
                print("Error pre-fetching training plan: \(error)")
              }
            }
          }
        }
      }
    }
  }

  private func fetchTrainingWeekData(completion: @escaping () -> Void) {
    guard let token = appState.jwtToken else {
      completion()
      return
    }

    APIManager.shared.fetchTrainingWeekData(token: token) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let trainingWeek):
          self.trainingWeekData = trainingWeek
        case .failure(let error):
          print("Error fetching training data: \(error)")
          self.trainingWeekData = nil
        }
        completion()
      }
    }
  }

  private func fetchWeeklySummaries(completion: @escaping () -> Void) {
    guard let token = appState.jwtToken else {
      completion()
      return
    }

    APIManager.shared.fetchWeeklySummaries(token: token) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let summaries):
          self.weeklySummaries = summaries
        case .failure(let error):
          print("Error fetching weekly summaries: \(error)")
          self.weeklySummaries = []
        }
        completion()
      }
    }
  }

  private func showErrorAlert(message: String) {
    self.errorMessage = message
    self.showErrorAlert = true
  }
}
