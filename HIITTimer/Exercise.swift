import Foundation

/// A user-defined timed activity. The app does not interpret what the name means.
struct Exercise: Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var workDuration: Int
    var restDuration: Int
    var rounds: Int

    static let durationRange = 5...300
    static let roundsRange = 1...99

    /// V1.0 default single-exercise configuration, named generically.
    static func makeDefault(index: Int = 1) -> Exercise {
        Exercise(
            id: UUID(),
            name: "Exercise \(index)",
            workDuration: 20,
            restDuration: 10,
            rounds: 8
        )
    }

    /// WORK × rounds + REST × (rounds − 1). No REST after the final round.
    var estimatedSeconds: Int {
        workDuration * rounds + restDuration * max(rounds - 1, 0)
    }

    var summaryLine: String {
        "\(workDuration)s WORK / \(restDuration)s REST × \(rounds)"
    }
}

enum WorkoutEstimate {
    /// Per-exercise time plus rest between exercises (never after the last one).
    static func totalSeconds(
        for exercises: [Exercise],
        restBetweenExercises: Int = 0
    ) -> Int {
        let exerciseTotal = exercises.reduce(0) { $0 + $1.estimatedSeconds }
        let gaps = max(exercises.count - 1, 0)
        return exerciseTotal + restBetweenExercises * gaps
    }

    static func formatDuration(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
