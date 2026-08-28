import Foundation
import Observation

@MainActor
@Observable
final class TabataTimer {
    enum Phase: Equatable {
        case idle
        case work
        case rest
        case interExerciseRest
        case completed
    }

    static let durationRange = 5...300
    static let roundsRange = 1...99

    /// Kept for SettingsView / V1.0 single-exercise compatibility.
    var workDuration = 20 {
        didSet {
            if phase == .idle && sessionExercises.isEmpty {
                secondsRemaining = workDuration
            }
        }
    }

    var restDuration = 10
    var totalRounds = 8

    private(set) var phase: Phase = .idle
    private(set) var secondsRemaining = 20
    private(set) var currentRound = 1
    private(set) var exerciseIndex = 0
    private(set) var isRunning = false

    /// Set when entering Completed; cleared on Reset / new workout.
    private(set) var workoutTimeSeconds = 0
    private(set) var totalTimeSeconds = 0
    private(set) var completedRoundCount = 0
    private(set) var completedExerciseCount = 0

    /// Snapshot of the workout being run (empty while idle after reset).
    private var sessionExercises: [Exercise] = []
    private var sessionRestBetweenExercises = 60

    private var timer: Timer?
    private let audio = WorkoutAudio()
    private var lastCountdownBeepSecond: Int?

    var formattedWorkoutTime: String {
        Self.formatDuration(workoutTimeSeconds)
    }

    var formattedTotalTime: String {
        Self.formatDuration(totalTimeSeconds)
    }

    var currentExerciseName: String {
        guard sessionExercises.indices.contains(exerciseIndex) else {
            return "Exercise 1"
        }
        return sessionExercises[exerciseIndex].name
    }

    var displayedExerciseNumber: Int {
        sessionExercises.isEmpty ? 1 : exerciseIndex + 1
    }

    var displayedExerciseCount: Int {
        max(sessionExercises.count, 1)
    }

    /// Rounds for the current exercise while a session is active.
    var displayedTotalRounds: Int {
        guard sessionExercises.indices.contains(exerciseIndex) else {
            return totalRounds
        }
        return sessionExercises[exerciseIndex].rounds
    }

    var canEditSettings: Bool {
        phase == .idle
    }

    var phaseTitle: String {
        switch phase {
        case .idle, .work:
            return "WORK"
        case .rest:
            return "REST"
        case .interExerciseRest:
            return "REST BETWEEN"
        case .completed:
            return "Completed"
        }
    }

    var canStart: Bool {
        !isRunning && phase != .completed
    }

    var canPause: Bool {
        isRunning
    }

    /// Starts a new workout from `exercises`, or resumes if paused mid-session.
    func start(exercises: [Exercise], restBetweenExercises: Int = 60) {
        guard canStart else { return }

        if phase == .idle {
            guard !exercises.isEmpty else { return }

            clearCompletionStats()
            sessionExercises = exercises
            sessionRestBetweenExercises = restBetweenExercises
            exerciseIndex = 0
            currentRound = 1
            phase = .work
            secondsRemaining = exercises[0].workDuration
            lastCountdownBeepSecond = nil
            audio.playStartVoice()
        }

        isRunning = true
        startTicking()
    }

    /// V1.0-compatible start using the single WORK/REST/ROUNDS settings.
    func start() {
        let single = Exercise(
            id: UUID(),
            name: "Exercise 1",
            workDuration: workDuration,
            restDuration: restDuration,
            rounds: totalRounds
        )
        start(exercises: [single], restBetweenExercises: 0)
    }

    func pause() {
        guard canPause else { return }
        isRunning = false
        stopTicking()
    }

    func reset() {
        stopTicking()
        isRunning = false
        phase = .idle
        exerciseIndex = 0
        currentRound = 1
        sessionExercises = []
        sessionRestBetweenExercises = 60
        secondsRemaining = workDuration
        lastCountdownBeepSecond = nil
        clearCompletionStats()
    }

    private func startTicking() {
        stopTicking()
        let scheduled = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
        RunLoop.main.add(scheduled, forMode: .common)
        timer = scheduled
    }

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        if secondsRemaining > 1 {
            secondsRemaining -= 1
            playCountdownBeepIfNeeded()
            return
        }

        advancePhase()
    }

    private func playCountdownBeepIfNeeded() {
        guard secondsRemaining == 3 || secondsRemaining == 2 || secondsRemaining == 1 else {
            return
        }
        guard lastCountdownBeepSecond != secondsRemaining else { return }
        lastCountdownBeepSecond = secondsRemaining
        audio.playCountdownBeep()
    }

    private func advancePhase() {
        lastCountdownBeepSecond = nil
        guard sessionExercises.indices.contains(exerciseIndex) else {
            complete()
            return
        }

        let exercise = sessionExercises[exerciseIndex]

        switch phase {
        case .work:
            if currentRound < exercise.rounds {
                phase = .rest
                secondsRemaining = exercise.restDuration
                audio.playRestVoice()
            } else if exerciseIndex + 1 < sessionExercises.count {
                phase = .interExerciseRest
                secondsRemaining = sessionRestBetweenExercises
                audio.playRestVoice()
            } else {
                complete()
            }
        case .rest:
            currentRound += 1
            phase = .work
            secondsRemaining = exercise.workDuration
            audio.playStartVoice()
        case .interExerciseRest:
            exerciseIndex += 1
            currentRound = 1
            phase = .work
            secondsRemaining = sessionExercises[exerciseIndex].workDuration
            audio.playStartVoice()
        case .idle, .completed:
            break
        }
    }

    private func complete() {
        stopTicking()
        isRunning = false
        phase = .completed
        secondsRemaining = 0
        lastCountdownBeepSecond = nil

        completedExerciseCount = sessionExercises.count
        completedRoundCount = sessionExercises.reduce(0) { $0 + $1.rounds }
        workoutTimeSeconds = sessionExercises.reduce(0) { $0 + $1.workDuration * $1.rounds }
        totalTimeSeconds = WorkoutEstimate.totalSeconds(
            for: sessionExercises,
            restBetweenExercises: sessionRestBetweenExercises
        )

        audio.playCongratulationsVoice()
    }

    private func clearCompletionStats() {
        workoutTimeSeconds = 0
        totalTimeSeconds = 0
        completedRoundCount = 0
        completedExerciseCount = 0
    }

    static func formatDuration(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
