import Foundation

/// A user-defined timed activity. The app does not interpret what the name means.
struct Exercise: Identifiable, Equatable, Hashable, Codable {
    var id: UUID
    var name: String
    var workDuration: Int
    var restDuration: Int
    var rounds: Int

    static let durationRange = 5...300
    static let roundsRange = 1...99
    static let countRange = 1...20

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

    /// Clamp numeric fields; fill blank names. Preserves `id`.
    func sanitized(displayIndex: Int) -> Exercise {
        var copy = self
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.name = trimmed.isEmpty ? "Exercise \(displayIndex)" : trimmed
        copy.workDuration = min(
            Self.durationRange.upperBound,
            max(Self.durationRange.lowerBound, workDuration)
        )
        copy.restDuration = min(
            Self.durationRange.upperBound,
            max(Self.durationRange.lowerBound, restDuration)
        )
        copy.rounds = min(
            Self.roundsRange.upperBound,
            max(Self.roundsRange.lowerBound, rounds)
        )
        return copy
    }
}

/// A named, independently saved workout configuration.
struct SavedWorkout: Identifiable, Equatable, Hashable, Codable {
    var id: UUID
    var name: String
    var exercises: [Exercise]
    var restBetweenExercises: Int

    static func makeDefault(name: String = "My Workout") -> SavedWorkout {
        SavedWorkout(
            id: UUID(),
            name: name,
            exercises: [Exercise.makeDefault(index: 1)],
            restBetweenExercises: 60
        )
    }

    func sanitized() -> SavedWorkout {
        var copy = self
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.name = trimmed.isEmpty ? "Untitled Workout" : trimmed

        var list = exercises
        if list.isEmpty {
            list = [Exercise.makeDefault(index: 1)]
        }
        let count = min(
            Exercise.countRange.upperBound,
            max(Exercise.countRange.lowerBound, list.count)
        )
        if list.count > count {
            list = Array(list.prefix(count))
        }
        copy.exercises = list.enumerated().map { index, exercise in
            exercise.sanitized(displayIndex: index + 1)
        }
        copy.restBetweenExercises = min(
            Exercise.durationRange.upperBound,
            max(Exercise.durationRange.lowerBound, restBetweenExercises)
        )
        return copy
    }
}

/// Library of saved workouts plus the one currently selected for the timer.
struct WorkoutLibrary: Equatable, Codable {
    var workouts: [SavedWorkout]
    var selectedWorkoutID: UUID?

    private static let storageKey = "workoutLibrary.v1"
    private static let legacyConfigKey = "workoutConfiguration.v1"
    private static let defaults = UserDefaults.standard

    static var `default`: WorkoutLibrary {
        let workout = SavedWorkout.makeDefault()
        return WorkoutLibrary(workouts: [workout], selectedWorkoutID: workout.id)
    }

    /// Always returns a valid selected workout (library is never empty after sanitize).
    var selectedWorkout: SavedWorkout {
        if let id = selectedWorkoutID,
           let match = workouts.first(where: { $0.id == id }) {
            return match
        }
        return workouts[0]
    }

    func sanitized() -> WorkoutLibrary {
        var copy = self
        if copy.workouts.isEmpty {
            return .default
        }
        copy.workouts = copy.workouts.map { $0.sanitized() }
        if copy.selectedWorkoutID == nil
            || !copy.workouts.contains(where: { $0.id == copy.selectedWorkoutID }) {
            copy.selectedWorkoutID = copy.workouts[0].id
        }
        return copy
    }

    static func load() -> WorkoutLibrary {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(WorkoutLibrary.self, from: data) {
            return decoded.sanitized()
        }

        // Migrate single V1.1/early-V1.2 config into one named workout, if present.
        if let legacyData = defaults.data(forKey: legacyConfigKey),
           let legacy = try? JSONDecoder().decode(LegacyWorkoutConfiguration.self, from: legacyData) {
            let migrated = SavedWorkout(
                id: UUID(),
                name: "My Workout",
                exercises: legacy.exercises,
                restBetweenExercises: legacy.restBetweenExercises
            ).sanitized()
            let library = WorkoutLibrary(
                workouts: [migrated],
                selectedWorkoutID: migrated.id
            )
            library.save()
            return library
        }

        return .default
    }

    func save() {
        let library = sanitized()
        guard let data = try? JSONEncoder().encode(library) else { return }
        Self.defaults.set(data, forKey: Self.storageKey)
    }

    mutating func select(_ id: UUID) {
        guard workouts.contains(where: { $0.id == id }) else { return }
        selectedWorkoutID = id
    }

    /// Append a brand-new workout and select it. Does not replace existing entries.
    mutating func insert(_ workout: SavedWorkout) {
        let clean = workout.sanitized()
        guard !workouts.contains(where: { $0.id == clean.id }) else {
            update(clean)
            return
        }
        workouts.append(clean)
        selectedWorkoutID = clean.id
    }

    /// Replace an existing workout with the same `id`, then select it.
    mutating func update(_ workout: SavedWorkout) {
        let clean = workout.sanitized()
        guard let index = workouts.firstIndex(where: { $0.id == clean.id }) else {
            insert(clean)
            return
        }
        workouts[index] = clean
        selectedWorkoutID = clean.id
    }

    /// Remove a workout. If it was selected, select another; if none remain, insert a default.
    mutating func delete(id: UUID) {
        workouts.removeAll { $0.id == id }
        if workouts.isEmpty {
            let fallback = SavedWorkout.makeDefault()
            workouts = [fallback]
            selectedWorkoutID = fallback.id
            return
        }
        if selectedWorkoutID == id
            || selectedWorkoutID == nil
            || !workouts.contains(where: { $0.id == selectedWorkoutID }) {
            selectedWorkoutID = workouts[0].id
        }
    }
}

/// Legacy single-config blob used before the multi-workout library.
private struct LegacyWorkoutConfiguration: Codable {
    var exercises: [Exercise]
    var restBetweenExercises: Int
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
