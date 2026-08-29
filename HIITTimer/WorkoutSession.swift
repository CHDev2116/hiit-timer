import Foundation

/// One completed workout saved for activity review.
struct WorkoutSessionRecord: Identifiable, Equatable, Codable {
    var id: UUID
    var completedAt: Date
    var workoutName: String
    var savedWorkoutID: UUID?
    var workoutTimeSeconds: Int
    var totalTimeSeconds: Int
    var completedRoundCount: Int
    var completedExerciseCount: Int
    var estimatedKcal: Int?
}
