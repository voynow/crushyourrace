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

  private var progressPercentage: Int {
    guard totalMileage > 0 else { return 0 }
    return Int((completedMileage / totalMileage) * 100)
  }

  private var weekRange: String {
    var calendar = Calendar.current
    calendar.firstWeekday = 2  // 2 represents Monday

    let today = Date()

    let monday =
      calendar.date(
        from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
      ) ?? today

    let sunday = calendar.date(byAdding: .day, value: 6, to: monday) ?? today

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d"
    return "\(dateFormatter.string(from: monday)) - \(dateFormatter.string(from: sunday))"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Weekly Progress")
          .font(.system(size: 24, weight: .semibold))
          .foregroundColor(ColorTheme.white)

        Text(weekRange)
          .font(.system(size: 14))
          .foregroundColor(ColorTheme.lightGrey)
      }

      HStack {
        Text("\(progressPercentage)%")
          .font(.system(size: 40, weight: .bold))
          .foregroundColor(ColorTheme.white)

        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          Text("\(Int(completedMileage)) of \(Int(totalMileage)) mi")
            .font(.subheadline)
            .foregroundColor(ColorTheme.white)

          Text("completed this week")
            .font(.caption)
            .foregroundColor(ColorTheme.midLightGrey)
        }
      }

      ProgressBar(progress: totalMileage > 0 ? completedMileage / totalMileage : 0)
        .frame(height: 8)
        .animation(.easeOut(duration: 0.8), value: completedMileage)
    }
    .padding(16)
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

  private var weekOverWeekChange: Double {
    guard displayedSummaries.count >= 2 else { return 0 }
    let current = displayedSummaries[0].totalDistance
    let previous = displayedSummaries[1].totalDistance
    return ((current - previous) / previous) * 100
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Last \(numberOfWeeks) Weeks")
          .font(.headline)
          .foregroundColor(ColorTheme.white)

        Spacer()

        if weekOverWeekChange != 0 {
          HStack(spacing: 4) {
            Image(systemName: weekOverWeekChange > 0 ? "arrow.up" : "arrow.down")
            Text(String(format: "%.1f%%", abs(weekOverWeekChange)))
          }
          .font(.caption)
          .foregroundColor(weekOverWeekChange > 0 ? ColorTheme.green : ColorTheme.redPink)
        }
      }

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

  private var sessionDate: Date {
    var calendar = Calendar.current
    calendar.firstWeekday = 2  // Monday

    // Get Monday of current week
    let today = Date()
    let monday =
      calendar.date(
        from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
      ) ?? today

    // Calculate days to add based on session.day
    let daysToAdd =
      switch session.day {
      case .mon: 0
      case .tues: 1
      case .wed: 2
      case .thurs: 3
      case .fri: 4
      case .sat: 5
      case .sun: 6
      }

    return calendar.date(byAdding: .day, value: daysToAdd, to: monday) ?? today
  }

  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: sessionDate)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .center, spacing: 16) {
        // Left column: Status and Date
        HStack(spacing: 16) {
          Circle()
            .fill(isCompleted ? ColorTheme.green : ColorTheme.darkGrey)
            .frame(width: 12, height: 12)
            .padding(.trailing, 6)

          VStack(alignment: .leading, spacing: 2) {
            Text(session.day.displayText)
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(ColorTheme.lightGrey)

            Text(formattedDate)
              .font(.system(size: 12))
              .foregroundColor(ColorTheme.midLightGrey)
          }
          .frame(width: 50, alignment: .leading)
        }

        // Middle column: Session Info
        VStack(alignment: .leading, spacing: 4) {
          Text(session.sessionType.rawValue.capitalized)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(ColorTheme.white)
          Text(String(format: "%.1f miles", session.distance))
            .font(.system(size: 14))
            .foregroundColor(ColorTheme.lightGrey)
        }

        Spacer()

        // Right column: Expand indicator
        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
          .foregroundColor(ColorTheme.lightGrey)
          .font(.system(size: 14))
      }

      if isExpanded {
        VStack(alignment: .leading, spacing: 8) {
          // Status pill
          Text(isCompleted ? "Completed" : "Upcoming")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isCompleted ? ColorTheme.green : ColorTheme.yellow)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
              (isCompleted ? ColorTheme.green : ColorTheme.yellow)
                .opacity(0.15)
            )
            .cornerRadius(4)

          if !session.notes.isEmpty {
            Text(session.notes)
              .font(.system(size: 14))
              .foregroundColor(ColorTheme.lightGrey)
              .lineSpacing(6)
              .padding(.top, 4)
          }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .background(ColorTheme.darkDarkGrey)
    .cornerRadius(12)
    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    .onTapGesture {
      withAnimation {
        isExpanded.toggle()
      }
    }
    // Add subtle hover effect
    .contentShape(Rectangle())
    .hoverEffect(.lift)
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
