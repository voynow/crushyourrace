import SwiftUI

struct TrainingWeekView: View {
  let trainingWeekData: FullTrainingWeek
  let weeklySummaries: [WeekSummary]?

  var body: some View {
    VStack(spacing: 16) {
      WeeklyProgressView(
        pastSessions: trainingWeekData.pastTrainingWeek.map(\.activity),
        futureSessions: trainingWeekData.futureTrainingWeek.sessions,
        weeklySummaries: weeklySummaries
      )
      SessionListView(
        sessions: trainingWeekData.pastTrainingWeek.map { enriched in
          TrainingSession(
            day: enriched.activity.dayOfWeek,
            sessionType: .easy,
            distance: enriched.activity.distanceInMiles,
            notes: enriched.coachesNotes
          )
        },
        isCompleted: true
      )
      SessionListView(
        sessions: trainingWeekData.futureTrainingWeek.sessions,
        isCompleted: false
      )
    }
    .padding(.horizontal, 16)
    .background(ColorTheme.black)
    .cornerRadius(16)
  }
}

struct WeeklyProgressView: View {
  let pastSessions: [DailyActivity]
  let futureSessions: [TrainingSession]
  let weeklySummaries: [WeekSummary]?
  @State private var showingMultiWeek: Bool = false

  private var completedMileage: Double {
    pastSessions.reduce(0) { $0 + $1.distanceInMiles }
  }

  private var totalMileage: Double {
    pastSessions.reduce(0) { $0 + $1.distanceInMiles }
      + futureSessions.reduce(0) { $0 + $1.distance }
  }

  var body: some View {
    VStack {
      if showingMultiWeek {
        if let summaries = weeklySummaries {
          MultiWeekProgressView(weeklySummaries: summaries, numberOfWeeks: 8)
            .transition(
              .asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity.combined(with: .move(edge: .top))
              ))
        } else {
          MultiWeekProgressSkeletonView()
            .transition(.opacity)
        }
      } else {
        WeeklyProgressContent(completedMileage: completedMileage, totalMileage: totalMileage)
          .transition(
            .asymmetric(
              insertion: .opacity.combined(with: .move(edge: .bottom)),
              removal: .opacity.combined(with: .move(edge: .top))
            ))
      }
    }
    .animation(.easeInOut(duration: 0.3), value: showingMultiWeek)
    .padding()
    .background(ColorTheme.darkDarkGrey)
    .cornerRadius(16)
    .onTapGesture {
      withAnimation {
        showingMultiWeek.toggle()
      }
    }
  }
}

struct WeeklyProgressContent: View {
  let completedMileage: Double
  let totalMileage: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {

      Text("Weekly Progress")
        .font(.headline)
        .foregroundColor(ColorTheme.white)

      HStack {
        Text("\(Int((completedMileage / totalMileage) * 100))%")
          .font(.system(size: 40, weight: .bold))
          .foregroundColor(ColorTheme.white)

        Spacer()

        Text("Completed \(Int(completedMileage)) of \(Int(totalMileage)) mi")
          .font(.subheadline)
          .foregroundColor(ColorTheme.midLightGrey)
      }
      .padding(.top, 6)

      ProgressBar(progress: completedMileage / totalMileage)
        .frame(height: 10)
        .animation(.easeOut(duration: 1.0), value: completedMileage)
    }
  }
}

struct MultiWeekProgressView: View {
  let weeklySummaries: [WeekSummary]
  let numberOfWeeks: Int

  private var displayedSummaries: [WeekSummary] {
    Array(weeklySummaries.prefix(numberOfWeeks))
  }

  private var maxMileage: Double {
    displayedSummaries.map(\.totalDistance).max() ?? 1
  }

  var body: some View {
    VStack(spacing: 12) {
      Text("Last \(numberOfWeeks) Weeks")
        .font(.headline)
        .foregroundColor(ColorTheme.white)
        .frame(maxWidth: .infinity, alignment: .leading)

      ForEach(displayedSummaries, id: \.parsedWeekStartDate) { summary in
        HStack(spacing: 10) {
          Text(weekLabel(for: summary.parsedWeekStartDate))
            .font(.subheadline)
            .foregroundColor(ColorTheme.lightGrey)
            .frame(width: 50, alignment: .leading)

          ProgressBar(progress: summary.totalDistance / maxMileage)
            .frame(height: 8)

          Text(String(format: "%.1f mi", summary.totalDistance))
            .font(.subheadline)
            .foregroundColor(ColorTheme.white)
            .frame(width: 60, alignment: .trailing)
        }
      }

      HStack {
        Spacer()
        Text("Total:")
          .font(.headline)
          .foregroundColor(ColorTheme.white)
        Text(String(format: "%.1f mi", displayedSummaries.reduce(0) { $0 + $1.totalDistance }))
          .font(.headline)
          .foregroundColor(ColorTheme.white)
      }
      .padding(.top, 8)
    }
  }

  private func weekLabel(for date: Date?) -> String {
    guard let date = date else { return "" }
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd"
    return formatter.string(from: date)
  }
}

struct ProgressBar: View {
  let progress: Double

  @State private var animatedProgress: CGFloat = 0

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Rectangle()
          .fill(ColorTheme.darkGrey)
        Rectangle()
          .fill(ColorTheme.primary)
          .frame(width: geometry.size.width * animatedProgress)
      }
    }
    .frame(height: 8)
    .cornerRadius(4)
    .onAppear {
      withAnimation(.easeOut(duration: 1.0)) {
        animatedProgress = CGFloat(progress)
      }
    }
  }
}

struct SessionListView: View {
  let sessions: [TrainingSession]
  let isCompleted: Bool

  var body: some View {
    VStack(spacing: 16) {
      ForEach(sessions) { session in
        SessionView(session: session, isCompleted: isCompleted)
      }
    }
  }
}

struct SessionView: View {
  let session: TrainingSession
  let isCompleted: Bool
  @State private var isExpanded: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      HStack(alignment: .center, spacing: 16) {
        Text(session.day.displayText)
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(ColorTheme.primaryLight)
          .frame(width: 40, alignment: .leading)

        VStack(alignment: .leading, spacing: 4) {
          Text(session.sessionType.rawValue)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(ColorTheme.white)
          Text(String(format: "%.1f mi", session.distance))
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(ColorTheme.lightGrey)
        }

        Spacer()

        Circle()
          .fill(isCompleted ? ColorTheme.green : ColorTheme.darkGrey)
          .frame(width: 16, height: 16)
      }

      if isExpanded {
        VStack(alignment: .leading, spacing: 4) {
          Text(isCompleted ? "Completed" : "Upcoming")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isCompleted ? ColorTheme.green : ColorTheme.yellow)

          if !session.notes.isEmpty {
            Text(session.notes)
              .font(.system(size: 14, weight: .regular))
              .foregroundColor(ColorTheme.lightGrey)
              .lineSpacing(4)
          }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .padding(.horizontal, 30)
    .padding(.vertical, 20)
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.darkGrey, lineWidth: 1))
    .background(ColorTheme.black)
    .cornerRadius(12)
    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isExpanded)
    .onTapGesture {
      withAnimation {
        isExpanded.toggle()
      }
    }
  }
}

struct MultiWeekProgressSkeletonView: View {
  let numberOfWeeks: Int = 8

  var body: some View {
    VStack(spacing: 12) {
      Text("Last \(numberOfWeeks) Weeks")
        .font(.headline)
        .foregroundColor(ColorTheme.white)
        .frame(maxWidth: .infinity, alignment: .leading)

      ForEach(0..<numberOfWeeks, id: \.self) { _ in
        HStack(spacing: 10) {
          Rectangle()
            .fill(ColorTheme.darkGrey)
            .frame(width: 50, height: 14)

          Rectangle()
            .fill(ColorTheme.darkGrey)
            .frame(height: 8)

          Rectangle()
            .fill(ColorTheme.darkGrey)
            .frame(width: 60, height: 14)
        }
      }

      HStack {
        Spacer()
        Rectangle()
          .fill(ColorTheme.darkGrey)
          .frame(width: 120, height: 16)
      }
      .padding(.top, 8)
    }
  }
}
