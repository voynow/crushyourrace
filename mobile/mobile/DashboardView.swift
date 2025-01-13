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

  var body: some View {
    let _ = print("[DashboardView] Rendering, auth strategy: \(appState.authStrategy)")

    ZStack {
      let _ = print("[DashboardView] Inside ZStack")
      ColorTheme.black.edgesIgnoringSafeArea(.all)

      TabView(selection: $appState.selectedTab) {
        let _ = print("[DashboardView] Inside TabView, selectedTab: \(appState.selectedTab)")
        VStack {
          DashboardNavbar(
            onLogout: { appState.clearAuthState() }, showProfile: $appState.showProfile
          )
          .background(ColorTheme.black)
          .zIndex(1)

          ScrollView {
            if appState.authStrategy == .apple {
              let _ = print("[DashboardView] Rendering Apple auth content")
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
              Text("No training data available")
                .font(.headline)
                .foregroundColor(ColorTheme.lightGrey)
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
  }

  private func fetchData() {
    if appState.authStrategy == .apple {
      return
    }

    isLoadingTrainingWeek = true
    fetchTrainingWeekData {
      isLoadingTrainingWeek = false
    }

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

  private func checkLoadingComplete() {
    if trainingWeekData != nil && weeklySummaries != nil {
      isLoadingTrainingWeek = false
    }
  }

  private func showErrorAlert(message: String) {
    self.errorMessage = message
    self.showErrorAlert = true
  }
}
