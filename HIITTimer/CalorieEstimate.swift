import Foundation

/// MET-based calorie estimation from workout timing statistics.
enum CalorieEstimate {
    static let workMET = 8.0
    static let restMET = 2.0

    /// Returns rounded kcal, or `nil` when weight is missing or invalid.
    static func estimatedKcal(
        weightKg: Double?,
        workoutTimeSeconds: Int,
        totalTimeSeconds: Int
    ) -> Int? {
        guard let weight = weightKg, weight > 0 else { return nil }
        guard workoutTimeSeconds >= 0, totalTimeSeconds >= workoutTimeSeconds else { return nil }

        let workHours = Double(workoutTimeSeconds) / 3600.0
        let restSeconds = totalTimeSeconds - workoutTimeSeconds
        let restHours = Double(restSeconds) / 3600.0

        let workKcal = workMET * weight * workHours
        let restKcal = restMET * weight * restHours
        return Int((workKcal + restKcal).rounded())
    }

    static func formattedEstimate(kcal: Int) -> String {
        "~\(kcal) kcal"
    }
}
