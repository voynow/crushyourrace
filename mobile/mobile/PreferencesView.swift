import SwiftUI

struct PickerTextStyle: ViewModifier {
  let isSelected: Bool

  func body(content: Content) -> some View {
    content
      .foregroundColor(isSelected ? ColorTheme.white : ColorTheme.lightGrey.opacity(0.6))
  }
}

struct PreferencesContainer: View {
  @Binding var preferences: Preferences
  @State private var isSaving: Bool = false
  @EnvironmentObject var appState: AppState

  var body: some View {
    ZStack {
      PreferencesContent(
        preferences: $preferences,
        onUpdate: savePreferences
      )

      if isSaving {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.white))
          .scaleEffect(1.5)
      }
    }
    .disabled(isSaving)
  }

  private func savePreferences() {
    guard let token = appState.jwtToken else {
      return
    }

    isSaving = true
    APIManager.shared.savePreferences(token: token, preferences: preferences) { result in
      DispatchQueue.main.async {
        isSaving = false
        switch result {
        case .success:
          // The SaveBanner is now handled within PreferencesContent
          break
        case .failure(let error):
          print("Failed to save preferences: \(error)")
        }
      }
    }
  }
}

struct SaveBanner: View {
  var body: some View {
    HStack {
      Image(systemName: "checkmark.circle.fill")
        .foregroundColor(ColorTheme.green)
      Text("Preferences saved")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(ColorTheme.white)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 16)
    .background(Color.black.opacity(0.6))
    .cornerRadius(8)
    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
  }
}

struct PreferencesContent: View {
  @Binding var preferences: Preferences
  var onUpdate: () -> Void
  @State private var activeSaveSection: String?
  @State private var showRaceSetupSheet: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      preferenceSectionView(
        title: "Race Details",
        subtitle: "Set up your target race",
        sectionId: "race"
      ) {
        if let raceDistance = preferences.raceDistance, let raceDate = preferences.raceDate {
          VStack(spacing: 16) {
            Button(action: { showRaceSetupSheet = true }) {
              VStack(spacing: 16) {
                preferenceRowView(
                  title: "Race Distance",
                  value: .constant(raceDistance)
                ) { _ in
                  Text(raceDistance)
                    .foregroundColor(ColorTheme.primary)
                }

                preferenceRowView(
                  title: "Race Date",
                  value: .constant(raceDate.formatted(date: .long, time: .omitted))
                ) { _ in
                  Text(raceDate.formatted(date: .long, time: .omitted))
                    .foregroundColor(ColorTheme.primary)
                }
              }
            }
          }
        } else {
          Button(action: { showRaceSetupSheet = true }) {
            HStack {
              Image(systemName: "plus.circle.fill")
              Text("Set up your race")
              Spacer()
            }
            .padding(.vertical, 8)
            .foregroundColor(ColorTheme.primaryLight)
          }
        }
      }

      preferenceSectionView(
        title: "Training Week",
        subtitle: "Help our AI understand your preferences",
        sectionId: "training"
      ) {
        ForEach(Day.allCases, id: \.self) { day in
          preferenceRowView(
            title: day.fullName,
            value: sessionTypeBinding(for: day)
          ) { binding in
            CustomPickerWrapper(
              selection: binding,
              content: AnyView(
                Picker("Session Type", selection: binding) {
                  Text("No Preference").tag("")
                  Text("Easy Run").tag("easy run")
                  Text("Long Run").tag("long run")
                  Text("Speed Workout").tag("speed workout")
                  Text("Rest Day").tag("rest day")
                  Text("Moderate Run").tag("moderate run")
                }
                .pickerStyle(MenuPickerStyle())
              )
            )
          }
        }
      }
    }
    .background(ColorTheme.black)
    .sheet(isPresented: $showRaceSetupSheet) {
      RaceSetupSheet(
        preferences: $preferences,
        isPresented: $showRaceSetupSheet,
        onSave: {
          onUpdate()
          showSaveBanner(for: "race")
        }
      )
    }
  }

  private func showSaveBanner(for section: String) {
    activeSaveSection = section
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      if activeSaveSection == section {
        activeSaveSection = nil
      }
    }
  }

  private func sessionTypeBinding(for day: Day) -> Binding<String> {
    Binding(
      get: {
        preferences.idealTrainingWeek?.first(where: { $0.day == day })?.sessionType ?? ""
      },
      set: { newValue in
        updateSessionType(for: day, with: newValue)
        showSaveBanner(for: "training")
      }
    )
  }

  private func updateSessionType(for day: Day, with newValue: String) {
    if preferences.idealTrainingWeek == nil {
      preferences.idealTrainingWeek = []
    }

    if newValue.isEmpty {
      preferences.idealTrainingWeek?.removeAll { $0.day == day }
    } else {
      if let index = preferences.idealTrainingWeek?.firstIndex(where: { $0.day == day }) {
        preferences.idealTrainingWeek?[index].sessionType = newValue
      } else {
        preferences.idealTrainingWeek?.append(TrainingDay(day: day, sessionType: newValue))
      }
    }
    onUpdate()
  }

  private func preferenceSectionView<Content: View>(
    title: String,
    subtitle: String,
    sectionId: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    ZStack(alignment: .topTrailing) {
      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 4) {
            Text(title)
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(ColorTheme.white)
            Text(subtitle)
              .font(.system(size: 14))
              .foregroundColor(ColorTheme.midLightGrey)
          }
          Spacer()
          if sectionId == "race" && preferences.raceDistance != nil {
            Button(action: clearRace) {
              Text("Clear Race")
                .foregroundColor(ColorTheme.redPink)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .opacity(0.75)
            }
            .background(ColorTheme.darkGrey)
            .cornerRadius(8)
          }
        }
        content()
      }
      .padding(24)
      .background(ColorTheme.darkDarkGrey)
      .cornerRadius(12)

      if activeSaveSection == sectionId {
        SaveBanner()
          .transition(.move(edge: .top).combined(with: .opacity))
          .animation(.easeInOut(duration: 0.3), value: activeSaveSection)
          .padding(.top, 8)
          .padding(.trailing, 8)
      }
    }
  }

  private func preferenceRowView<Value: Equatable, EditContent: View>(
    title: String,
    value: Binding<Value>,
    @ViewBuilder editContent: (Binding<Value>) -> EditContent
  ) -> some View {
    HStack {
      Text(title)
        .font(.system(size: 16))
        .foregroundColor(ColorTheme.primaryLight)
      Spacer()
      editContent(value)
        .foregroundColor(ColorTheme.lightGrey)
    }
    .padding(.horizontal, 12)
  }

  private func clearRace() {
    preferences.raceDistance = nil
    preferences.raceDate = nil
    onUpdate()
    showSaveBanner(for: "race")
  }
}

struct CustomPickerWrapper: View {
  @Binding var selection: String
  let content: AnyView

  var body: some View {
    content
      .opacity(selection.isEmpty ? 0.4 : 1.0)
  }
}

struct RaceSetupSheet: View {
  @Binding var preferences: Preferences
  @Binding var isPresented: Bool
  let onSave: () -> Void

  @State private var selectedDistance: String = ""
  @State private var selectedDate: Date = Date()

  var body: some View {
    NavigationView {
      Form {
        Picker("Race Distance", selection: $selectedDistance) {
          Text("Select Distance").tag("")
          Text("5K").tag("5K")
          Text("10K").tag("10K")
          Text("Half Marathon").tag("Half Marathon")
          Text("Marathon").tag("Marathon")
          Text("Ultra Marathon").tag("Ultra Marathon")
        }

        DatePicker(
          "Race Date",
          selection: $selectedDate,
          in: Date()...,
          displayedComponents: .date
        )
      }
      .navigationTitle("Set Up Race")
      .navigationBarItems(
        leading: Button("Cancel") { isPresented = false },
        trailing: Button("Save") {
          guard !selectedDistance.isEmpty else { return }
          preferences.raceDistance = selectedDistance
          preferences.raceDate = selectedDate
          
          onSave()
          isPresented = false
        }
        .disabled(selectedDistance.isEmpty)
      )
    }
    .onAppear {
      if let existingDistance = preferences.raceDistance {
        selectedDistance = existingDistance
      }
      if let existingDate = preferences.raceDate {
        selectedDate = existingDate
      }
    }
  }
}
