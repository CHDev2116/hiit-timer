import Foundation

/// Append-only local store of completed workout sessions.
struct WorkoutHistory: Equatable, Codable {
    var sessions: [WorkoutSessionRecord]

    private static let storageKey = "workoutHistory.v1"
    private static let defaults = UserDefaults.standard

    static var empty: WorkoutHistory {
        WorkoutHistory(sessions: [])
    }

    static func load() -> WorkoutHistory {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(WorkoutHistory.self, from: data) else {
            return .empty
        }
        return decoded.sanitized()
    }

    func save() {
        let history = sanitized()
        guard let data = try? JSONEncoder().encode(history) else { return }
        Self.defaults.set(data, forKey: Self.storageKey)
    }

    func sanitized() -> WorkoutHistory {
        var copy = self
        copy.sessions = copy.sessions.filter { session in
            session.workoutTimeSeconds >= 0
                && session.totalTimeSeconds >= session.workoutTimeSeconds
                && session.completedRoundCount >= 0
                && session.completedExerciseCount >= 0
        }
        return copy
    }

    mutating func append(_ record: WorkoutSessionRecord) {
        sessions.append(record)
    }
}
