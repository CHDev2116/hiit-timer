# HIIT Timer

**Version 1.0**

A personal interval workout timer for iPhone, built with SwiftUI.

Goal: **start fast, few steps, works offline**. Not a social fitness platform.

## Features (v1.0)

- Large countdown with WORK / REST phase and current round
- Configurable settings:
  - WORK: 5–300 seconds (default 20)
  - REST: 5–300 seconds (default 10)
  - ROUNDS: 1–99 (default 8)
- **Estimated Time** shown before you start (includes every WORK; REST only between rounds)
- Voice cues:
  - WORK starts → “Start”
  - REST starts → “Rest”
  - Workout complete → “Congratulations!”
- Beeps at 3 / 2 / 1 seconds
- Completion summary: Workout Time, Total Time, and completed rounds
- Settings live on a separate screen so the timer stays uncluttered

## Not in scope (for later versions)

- Accounts / cloud sync
- Apple Watch
- Persistent workout history
- Background / lock-screen timing
- Social features, nutrition, or course marketplaces

## Tech

| Area | Choice |
|------|--------|
| UI | SwiftUI |
| State | `@Observable` |
| Audio | AVFoundation (bundled `.wav` files) |
| Minimum OS | iOS 17 |
| Device | iPhone |

## Project structure

```
HIITTimer/
  HIITTimerApp.swift      # App entry
  ContentView.swift       # Main timer + completion summary
  SettingsView.swift      # WORK / REST / ROUNDS
  TabataTimer.swift       # Timer state machine + stats
  WorkoutAudio.swift      # Sound playback
  Sounds/                 # Voice and cue audio
  Assets.xcassets/
HIIT Timer.xcodeproj/
```

## Run in Xcode

1. Open `HIIT Timer.xcodeproj`
2. Choose an iPhone simulator or device
3. Press Run

If the iOS Simulator runtime is missing:

```bash
xcodebuild -downloadPlatform iOS
```

## Estimated Time formula

```
estimatedTotalSeconds =
  workDuration × rounds +
  restDuration × (rounds − 1)
```

REST after the final round is **not** included in the estimate.

## License

Personal learning / portfolio project. A formal license can be added later if needed.
