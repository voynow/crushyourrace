import SwiftUI

struct RaceSetupSheet: View {
  @Binding var preferences: Preferences
  @Binding var isPresented: Bool
  let onSave: () -> Void

  @State private var selectedDistance: String = ""
  @State private var selectedDate: Date = Date()
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var showError = false

  @EnvironmentObject var appState: AppState

  var body: some View {
    NavigationView {
      Form {
        Section {
          Picker("Race Distance", selection: $selectedDistance) {
            Text("Select Distance").tag("")
            Text("5K").tag("5K")
            Text("10K").tag("10K")
            Text("Half Marathon").tag("Half Marathon")
            Text("Marathon").tag("Marathon")
            Text("Ultra Marathon").tag("Ultra Marathon")
          }
          .pickerStyle(MenuPickerStyle())

          DatePicker(
            "Race Date",
            selection: $selectedDate,
            in: Date()...,
            displayedComponents: .date
          )
        }

        Section {
          VStack(alignment: .center, spacing: 16) {
            InfoRow(
              icon: "target",
              text: "Set a goal to stay motivated"
            )

            InfoRow(
              icon: "figure.run",
              text: "Your training plan will update automatically"
            )

            InfoRow(
              icon: "calendar.badge.clock",
              text: "You can adjust your race anytime"
            )
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
      }
      .navigationTitle("Set a Race Goal")
      .navigationBarItems(
        leading: Button("Cancel") { isPresented = false }
          .disabled(isLoading),
        trailing: Button(action: handleSave) {
          HStack(spacing: 8) {
            if isLoading {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            }
            Text(isLoading ? "Saving..." : "Save")
              .foregroundColor(.white)
          }
          .frame(minWidth: isLoading ? 100 : 60)
          .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
        .disabled(selectedDistance.isEmpty || isLoading)
        .opacity(selectedDistance.isEmpty ? 0.6 : 1)
      )
    }
    .preferredColorScheme(.dark)
    .onAppear {
      if let existingDistance = preferences.raceDistance {
        selectedDistance = existingDistance
      }
      if let existingDate = preferences.raceDate {
        selectedDate = existingDate
      }
    }
  }

  private func handleSave() {
    guard !selectedDistance.isEmpty else { return }
    guard let token = appState.jwtToken else {
      showError(message: "No token found")
      return
    }

    isLoading = true
    preferences.raceDistance = selectedDistance
    preferences.raceDate = selectedDate

    APIManager.shared.savePreferences(token: token, preferences: preferences) { result in
      DispatchQueue.main.async {
        isLoading = false
        switch result {
        case .success:
          onSave()
          isPresented = false
        case .failure(let error):
          showError(message: "Failed to save preferences: \(error.localizedDescription)")
        }
      }
    }
  }

  private func showError(message: String) {
    errorMessage = message
    showError = true
  }
}

private struct InfoRow: View {
  let icon: String
  let text: String

  var body: some View {
    HStack {
      Image(systemName: icon)
        .foregroundColor(.blue)
      Text(text)
        .foregroundColor(.secondary)
        .font(.subheadline)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(width: 300)
  }
}
