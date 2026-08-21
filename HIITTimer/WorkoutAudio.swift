import AVFoundation
import Foundation

/// Thin AVFoundation wrapper for Tabata cue sounds.
/// Missing or unloadable resources fail silently.
@MainActor
final class WorkoutAudio {
    private var players: [Cue: AVAudioPlayer] = [:]
    private var didConfigureSession = false

    private enum Cue: String, CaseIterable {
        case beep
        case start
        case rest
        case congratulations
        case workStart = "work_start"
        case restStart = "rest_start"
        case complete
    }

    init() {
        configureSessionIfNeeded()
        for cue in Cue.allCases {
            load(cue)
        }
    }

    func playCountdownBeep() {
        play(.beep)
    }

    /// Spoken "Start" — once whenever a WORK phase begins.
    func playStartVoice() {
        play(.start)
    }

    /// Spoken "Rest" — once whenever a REST phase begins.
    func playRestVoice() {
        play(.rest)
    }

    /// Spoken "Congratulations!" — once when entering Completed.
    func playCongratulationsVoice() {
        play(.congratulations)
    }

    func playWorkStart() {
        play(.workStart)
    }

    func playRestStart() {
        play(.restStart)
    }

    func playComplete() {
        play(.complete)
    }

    private func configureSessionIfNeeded() {
        guard !didConfigureSession else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            didConfigureSession = true
        } catch {
            // Keep going; playback may still work with the default session.
        }
    }

    private func load(_ cue: Cue) {
        guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav") else {
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[cue] = player
        } catch {
            // Resource present but unloadable — skip this cue.
        }
    }

    private func play(_ cue: Cue) {
        guard let player = players[cue] else { return }
        player.currentTime = 0
        player.play()
    }
}
