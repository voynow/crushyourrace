import Foundation
import SwiftUI

struct ProfileData: Codable {
  var firstname: String
  var lastname: String
  var email: String?
  var profile: String
  var preferences: String?

  enum CodingKeys: String, CodingKey {
    case firstname, lastname, email, profile, preferences
  }
}

enum Day: String, CaseIterable, Codable {
  case mon = "Mon"
  case tues = "Tue"
  case wed = "Wed"
  case thurs = "Thu"
  case fri = "Fri"
  case sat = "Sat"
  case sun = "Sun"

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode(String.self)

    // Normalize variations
    let normalizedValue =
      value
      .replacingOccurrences(of: "Tues", with: "Tue")
      .replacingOccurrences(of: "Thurs", with: "Thu")
      .capitalized

    guard let day = Day(rawValue: normalizedValue) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Cannot initialize Day from invalid String value \(value)"
      )
    }
    self = day
  }

  var fullName: String {
    switch self {
    case .mon: return "Monday"
    case .tues: return "Tuesday"
    case .wed: return "Wednesday"
    case .thurs: return "Thursday"
    case .fri: return "Friday"
    case .sat: return "Saturday"
    case .sun: return "Sunday"
    }
  }

  var displayText: String {
    rawValue.uppercased()
  }
}

struct TrainingDay: Codable {
  let day: Day
  var sessionType: String

  enum CodingKeys: String, CodingKey {
    case day
    case sessionType = "session_type"
  }
}

struct Preferences: Codable {
  var raceDistance: String?
  var raceDate: Date?
  var idealTrainingWeek: [TrainingDay]?

  enum CodingKeys: String, CodingKey {
    case raceDistance = "race_distance"
    case raceDate = "race_date"
    case idealTrainingWeek = "ideal_training_week"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    raceDistance = try container.decodeIfPresent(String.self, forKey: .raceDistance)
    idealTrainingWeek = try container.decodeIfPresent(
      [TrainingDay].self, forKey: .idealTrainingWeek)

    // Parse date as YYYY-MM-DD
    if let dateString = try container.decodeIfPresent(String.self, forKey: .raceDate) {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      raceDate = formatter.date(from: dateString)
    } else {
      raceDate = nil
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(raceDistance, forKey: .raceDistance)
    try container.encodeIfPresent(idealTrainingWeek, forKey: .idealTrainingWeek)

    // Format date as YYYY-MM-DD only
    if let date = raceDate {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      try container.encode(formatter.string(from: date), forKey: .raceDate)
    }
  }

  init() {
    self.raceDistance = nil
    self.raceDate = nil
    self.idealTrainingWeek = nil
  }
}

extension Notification.Name {
  static let didSetupRace = Notification.Name("didSetupRace")
}

struct SavePreferencesResponse: Codable {
  let success: Bool
  let error: String?
}

struct TrainingWeekData: Codable {
  let sessions: [TrainingSession]
}

enum SessionType: String, Codable {
  case easy = "easy run"
  case long = "long run"
  case speed = "speed workout"
  case rest = "rest day"
}

struct DailyActivity: Codable {
  let date: String
  let dayOfWeek: Day
  let weekOfYear: Int
  let year: Int
  let distanceInMiles: Double
  let elevationGainInFeet: Double
  let movingTimeInMinutes: Double
  let paceMinutesPerMile: Double?
  let activityCount: Int
  let activityIds: [Int]

  enum CodingKeys: String, CodingKey {
    case date
    case dayOfWeek = "day_of_week"
    case weekOfYear = "week_of_year"
    case year
    case distanceInMiles = "distance_in_miles"
    case elevationGainInFeet = "elevation_gain_in_feet"
    case movingTimeInMinutes = "moving_time_in_minutes"
    case paceMinutesPerMile = "pace_minutes_per_mile"
    case activityCount = "activity_count"
    case activityIds = "activity_ids"
  }
}

struct EnrichedActivity: Codable {
  let activity: DailyActivity
  let coachesNotes: String

  enum CodingKeys: String, CodingKey {
    case activity
    case coachesNotes = "coaches_notes"
  }
}

struct TrainingSession: Codable, Identifiable {
  let id: UUID
  let day: Day
  let sessionType: SessionType
  let distance: Double
  let notes: String

  init(id: UUID = UUID(), day: Day, sessionType: SessionType, distance: Double, notes: String) {
    self.id = id
    self.day = day
    self.sessionType = sessionType
    self.distance = distance
    self.notes = notes
  }

  enum CodingKeys: String, CodingKey {
    case day
    case sessionType = "session_type"
    case distance, notes
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = UUID()
    day = try container.decode(Day.self, forKey: .day)
    sessionType = try container.decode(SessionType.self, forKey: .sessionType)
    distance = try container.decode(Double.self, forKey: .distance)
    notes = try container.decode(String.self, forKey: .notes)
  }
}

struct TrainingWeek: Codable {
  let sessions: [TrainingSession]
}

struct FullTrainingWeek: Codable {
  let pastTrainingWeek: [EnrichedActivity]
  let futureTrainingWeek: TrainingWeek

  enum CodingKeys: String, CodingKey {
    case pastTrainingWeek = "past_training_week"
    case futureTrainingWeek = "future_training_week"
  }
}

struct ProfileResponse: Codable {
  let success: Bool
  let message: String?
  let profile: ProfileData?
}

struct TrainingWeekResponse: Codable {
  let success: Bool
  let message: String?
  let trainingWeek: String?

  enum CodingKeys: String, CodingKey {
    case success, message
    case trainingWeek = "training_week"
  }
}

struct SignupResponse: Codable {
  let success: Bool
  let jwt_token: String
  let user_id: String?
  let is_new_user: Bool?
}

struct RefreshTokenResponse: Codable {
  let success: Bool
  let message: String?
  let jwt_token: String?
}

struct WeekSummary: Codable {
  var year: Int
  var weekOfYear: Int
  var weekStartDate: String
  var longestRun: Double
  var totalDistance: Double

  enum CodingKeys: String, CodingKey {
    case year
    case weekOfYear = "week_of_year"
    case weekStartDate = "week_start_date"
    case longestRun = "longest_run"
    case totalDistance = "total_distance"
  }

  var parsedWeekStartDate: Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: weekStartDate.prefix(10).description)
  }
}

struct WeeklySummariesResponse: Codable {
  let success: Bool
  let message: String?
  let weekly_summaries: [String]?
}

struct GenerateTrainingPlanResponse: Codable {
  let success: Bool
}

enum AppStateStatus {
  case loggedOut
  case loading
  case newUser
  case loggedIn
  case generatingPlan
}

struct GenericResponse: Codable {
  let success: Bool
  let message: String?
}

enum WeekType: String, Codable {
  case build = "build"
  case peak = "peak"
  case taper = "taper"
  case race = "race"

  var color: Color {
    switch self {
    case .build: return ColorTheme.orange
    case .peak: return ColorTheme.redPink
    case .taper: return ColorTheme.yellow
    case .race: return ColorTheme.green
    }
  }
}

struct TrainingPlanWeek: Codable, Identifiable {
  let weekStartDate: Date
  let weekNumber: Int
  let nWeeksUntilRace: Int
  let weekType: WeekType
  let notes: String
  let totalDistance: Double
  let longRunDistance: Double

  var id: Int { weekNumber }

  enum CodingKeys: String, CodingKey {
    case weekStartDate = "week_start_date"
    case weekNumber = "week_number"
    case nWeeksUntilRace = "n_weeks_until_race"
    case weekType = "week_type"
    case notes
    case totalDistance = "total_distance"
    case longRunDistance = "long_run_distance"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Handle date string conversion
    let dateString = try container.decode(String.self, forKey: .weekStartDate)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    guard let date = formatter.date(from: dateString) else {
      throw DecodingError.dataCorruptedError(
        forKey: .weekStartDate, in: container, debugDescription: "Date string does not match format"
      )
    }
    weekStartDate = date

    // Decode other properties normally
    weekNumber = try container.decode(Int.self, forKey: .weekNumber)
    nWeeksUntilRace = try container.decode(Int.self, forKey: .nWeeksUntilRace)
    weekType = try container.decode(WeekType.self, forKey: .weekType)
    notes = try container.decode(String.self, forKey: .notes)
    totalDistance = try container.decode(Double.self, forKey: .totalDistance)
    longRunDistance = try container.decode(Double.self, forKey: .longRunDistance)
  }
}

struct TrainingPlan: Codable {
  let trainingPlanWeeks: [TrainingPlanWeek]

  var isEmpty: Bool {
    trainingPlanWeeks.isEmpty
  }

  enum CodingKeys: String, CodingKey {
    case trainingPlanWeeks = "training_plan_weeks"
  }
}
