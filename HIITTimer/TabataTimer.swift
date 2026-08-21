import Foundation
import Observation

@MainActor
@Observable
final class TabataTimer {
    enum Phase: Equatable {
        case idle
        case work
        case rest
        case completed
    }

    static let durationRange = 5...300
    static let roundsRange = 1...99

    /// User-configurable settings (edited while idle).
    var workDuration = 20 {
        didSet {
            if phase == .idle {
                secondsRemaining = workDuration
            }
        }
    }

    var restDuration = 10
    var totalRounds = 8

    private(set) var phase: Phase = .idle
    private(set) var secondsRemaining = 20
    private(set) var currentRound = 1
    private(set) var isRunning = false

    /// Set when entering Completed; cleared on Reset / new workout.
    private(set) var workoutTimeSeconds = 0
    private(set) var totalTimeSeconds = 0
    private(set) var completedRoundCount = 0

    /// Locked in when a workout begins; ignored settings changes mid-session.
    private var sessionWorkDuration = 20
    private var sessionRestDuration = 10
    private var sessionTotalRounds = 8

    private var timer: Timer?
    private let audio = WorkoutAudio()
    /// Prevents replaying the same countdown second if tick logic is invoked again.
    private var lastCountdownBeepSecond: Int?

    var formattedWorkoutTime: String {
        Self.formatDuration(workoutTimeSeconds)
    }

    var formattedTotalTime: String {
        Self.formatDuration(totalTimeSeconds)
    }

    /// Planning estimate: all WORK + REST between rounds only (no final REST).
    var estimatedTotalSeconds: Int {
        workDuration * totalRounds + restDuration * max(totalRounds - 1, 0)
    }

    var formattedEstimatedTime: String {
        Self.formatDuration(estimatedTotalSeconds)
    }

    /// Rounds shown in the UI: session value while active, otherwise the setting.
    var displayedTotalRounds: Int {
        phase == .idle ? totalRounds : sessionTotalRounds
    }

    var canEditSettings: Bool {
        phase == .idle
    }

    var phaseTitle: String {
        switch phase {
        case .idle:
            return "WORK"
        case .work:
            return "WORK"
        case .rest:
            return "REST"
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

    func start() {
        guard canStart else { return }

        if phase == .idle {
            clearCompletionStats()

            sessionWorkDuration = workDuration
            sessionRestDuration = restDuration
            sessionTotalRounds = totalRounds

            phase = .work
            currentRound = 1
            secondsRemaining = sessionWorkDuration
            lastCountdownBeepSecond = nil
            audio.playStartVoice()
        }

        isRunning = true
        startTicking()
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
        currentRound = 1
        secondsRemaining = workDuration
        lastCountdownBeepSecond = nil
        clearCompletionStats()
    }

    private func startTicking() {
        stopTicking()
        let scheduled = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
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

        switch phase {
        case .work:
            phase = .rest
            secondsRemaining = sessionRestDuration
            audio.playRestVoice()
        case .rest:
            if currentRound >= sessionTotalRounds {
                complete()
            } else {
                currentRound += 1
                phase = .work
                secondsRemaining = sessionWorkDuration
                audio.playStartVoice()
            }
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

        completedRoundCount = sessionTotalRounds
        workoutTimeSeconds = sessionWorkDuration * sessionTotalRounds
        totalTimeSeconds = (sessionWorkDuration + sessionRestDuration) * sessionTotalRounds

        audio.playCongratulationsVoice()
    }

    private func clearCompletionStats() {
        workoutTimeSeconds = 0
        totalTimeSeconds = 0
        completedRoundCount = 0
    }

    static func formatDuration(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
