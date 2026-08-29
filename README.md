# HIIT Timer

**Version 2.0 — Workout Dashboard**

A personal interval workout timer for iPhone, built with SwiftUI.

Goal: **start fast, few steps, works offline**. Not a social fitness platform.

This is a daily-driver app you can use for real workouts — not just a prototype.

**Latest tagged release:** `v2.0.0` — Workout Dashboard

## Features

### Timer

- Large countdown with WORK / REST phase and current round
- Multi-exercise workouts with rest between exercises
- Voice cues:
  - WORK starts → “Start”
  - REST starts → “Rest”
  - Workout complete → “Congratulations!”
- Beeps at 3 / 2 / 1 seconds
- Completion summary: workout name, Workout Time, Total Time, rounds, and exercises
- **Estimated calories** on completion when weight is configured (see below)
- Start / Pause / Reset controls; timer UI stays uncluttered

### Workout library (Settings)

Open the gear icon on the Timer tab to manage workouts:

- **Saved workouts** — create, edit, select, and delete named workouts
- Each workout supports 1–20 exercises with per-exercise WORK, REST, and ROUNDS
- REST between exercises (5–300 seconds)
- **Estimated Time** shown in the editor (includes WORK, between-round REST, and rest between exercises)
- **Calorie Estimate** — set your weight (kg) for post-workout calorie estimates
- Selecting a different workout after completion returns the timer to ready state

### Workout Dashboard (v2.0)

The Dashboard tab provides a simple activity overview based on completed workouts:

- **Last 7 Days** — one bar per day for the current day plus the previous six calendar days
- **This Month** — weekly buckets for the current calendar month
- **Bar chart** — primary visualization of workout activity
- **Workout count** — number of completed sessions in the selected period
- **Total workout time** — combined workout time for the period
- **Estimated calories** — sum of calorie snapshots where available

**Monthly view:** buckets are grouped as `1–7`, `8–14`, `15–21`, `22–28`, and `29–31`. If a month crosses into another calendar week, the visualization may continue the weekday sequence naturally across the boundary.

The Timer remains the primary workout screen. Workout settings and the saved workout library stay separate from the Dashboard.

### Workout history

Completed workouts are stored locally as workout history:

- A session is recorded **only after a workout is fully completed**
- History is stored on the device only (`UserDefaults` + JSON, key `workoutHistory.v1`)
- No cloud sync, iCloud, or HealthKit
- Deleting or renaming a saved workout does **not** erase historical session records
- Historical calorie estimates are **snapshots** taken at completion time

### Estimated calories (v1.3)

Optional, local-only weight setting:

- Configure weight in **Settings → Calorie Estimate**
- After a completed workout, the summary shows `~N kcal` when weight is set
- Simple MET-based model: WORK = 8.0 MET, REST = 2.0 MET
- Result is an estimate; displayed with `~`
- No age, sex, height, or unit conversion in this version
- Stored on device only (`UserDefaults`); no cloud or HealthKit

## Version history

| Version | Highlights |
|---------|------------|
| **1.0** | Single-exercise timer, voice cues, completion stats |
| **1.1** | Multi-exercise workout configuration |
| **1.2** | Saved workout library, workout editor, timer launches to main screen |
| **1.3** | Estimated calories, weight profile, completion/workout-selection state fix |
| **2.0** | Workout Dashboard, workout history, 7-day and monthly activity visualization |

## Not in scope (for later versions)

- Accounts / cloud sync / iCloud
- Apple Watch
- Background / lock-screen timing
- Social features, nutrition tracking beyond simple estimates, or course marketplaces
- HealthKit integration

## Tech

| Area | Choice |
|------|--------|
| UI | SwiftUI |
| State | `@Observable` (`TabataTimer`) |
| Persistence | `UserDefaults` + JSON (`WorkoutLibrary`, `UserProfile`, `WorkoutHistory`) |
| Charts | Swift Charts |
| Audio | AVFoundation (bundled `.wav` files) |
| Minimum OS | iOS 17 |
| Device | iPhone |

## Project structure

```
HIITTimer/
  HIITTimerApp.swift        # App entry (Timer + Dashboard tabs)
  ContentView.swift         # Main timer + completion summary
  DashboardView.swift       # Workout Dashboard
  DashboardAggregation.swift # Dashboard period stats and chart buckets
  WorkoutSession.swift      # Completed session record model
  WorkoutHistory.swift      # Local workout history persistence
  WorkoutBuilderView.swift  # Workout library + editor (Settings)
  PersonalProfileView.swift # Weight for calorie estimates
  Exercise.swift            # Exercise, SavedWorkout, WorkoutLibrary
  UserProfile.swift         # Local weight profile
  CalorieEstimate.swift     # MET-based calorie calculation
  TabataTimer.swift         # Timer state machine + stats
  WorkoutAudio.swift        # Sound playback
  SettingsView.swift        # Legacy V1.0 settings (unused)
  Sounds/                   # Voice and cue audio
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

Build from the command line:

```bash
xcodebuild -scheme "HIIT Timer" -destination 'generic/platform=iOS Simulator' build
```

## Formulas

### Estimated workout time (per exercise)

```
exerciseSeconds =
  workDuration × rounds +
  restDuration × (rounds − 1)
```

REST after the final round is **not** included.

Multi-exercise total adds rest-between-exercise gaps (never after the last exercise).

### Estimated calories (completion summary)

```
workKcal  = 8.0 × weightKg × (workoutTimeSeconds / 3600)
restKcal  = 2.0 × weightKg × ((totalTimeSeconds − workoutTimeSeconds) / 3600)
kcal      = round(workKcal + restKcal)
```

Displayed as `~N kcal`. Shown only when a valid weight is configured.

## License

No formal open-source license yet.

Built as a personal learning / portfolio project for my own use. A license (for example MIT) can be added later if redistribution terms become useful.
