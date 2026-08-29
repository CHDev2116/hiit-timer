import SwiftUI

struct ContentView: View {
    @State private var library = WorkoutLibrary.load()
    @State private var userProfile = UserProfile.load()
    @State private var timer = TabataTimer()
    @State private var showingSettings = false
    @State private var selectedWorkoutIDWhenSettingsOpened: UUID?
    @State private var sessionWorkoutName: String?
    @State private var sessionSavedWorkoutID: UUID?
    @State private var didRecordCurrentCompletion = false

    private var selectedWorkout: SavedWorkout {
        library.selectedWorkout
    }

    /// Library editing is blocked during an active session, but allowed when idle or after completion.
    private var canEditWorkoutLibrary: Bool {
        timer.canEditSettings || timer.phase == .completed
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if timer.phase == .completed {
                completedSummary
            } else {
                activeTimerContent
            }

            Spacer()

            HStack(spacing: 16) {
                Button("Start") {
                    sessionWorkoutName = selectedWorkout.name
                    sessionSavedWorkoutID = selectedWorkout.id
                    timer.start(
                        exercises: selectedWorkout.exercises,
                        restBetweenExercises: selectedWorkout.restBetweenExercises
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(!timer.canStart)

                Button("Pause") {
                    timer.pause()
                }
                .buttonStyle(.bordered)
                .disabled(!timer.canPause)

                Button("Reset") {
                    timer.reset()
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 32)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedWorkoutIDWhenSettingsOpened = library.selectedWorkout.id
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showingSettings, onDismiss: {
            library = WorkoutLibrary.load()
            userProfile = UserProfile.load()
            if timer.phase == .completed,
               let previousID = selectedWorkoutIDWhenSettingsOpened,
               library.selectedWorkout.id != previousID {
                timer.reset()
            }
        }) {
            WorkoutLibraryView(canEdit: canEditWorkoutLibrary)
        }
        .onChange(of: timer.phase) { _, newPhase in
            switch newPhase {
            case .completed:
                if !didRecordCurrentCompletion {
                    recordCompletedWorkout()
                    didRecordCurrentCompletion = true
                }
            case .idle:
                didRecordCurrentCompletion = false
                sessionWorkoutName = nil
                sessionSavedWorkoutID = nil
            default:
                break
            }
        }
    }

    private func recordCompletedWorkout() {
        let name = sessionWorkoutName ?? selectedWorkout.name
        let record = WorkoutSessionRecord(
            id: UUID(),
            completedAt: Date(),
            workoutName: name,
            savedWorkoutID: sessionSavedWorkoutID,
            workoutTimeSeconds: timer.workoutTimeSeconds,
            totalTimeSeconds: timer.totalTimeSeconds,
            completedRoundCount: timer.completedRoundCount,
            completedExerciseCount: timer.completedExerciseCount,
            estimatedKcal: CalorieEstimate.estimatedKcal(
                weightKg: userProfile.weightKg,
                workoutTimeSeconds: timer.workoutTimeSeconds,
                totalTimeSeconds: timer.totalTimeSeconds
            )
        )

        var history = WorkoutHistory.load()
        history.append(record)
        history.save()
    }

    private var activeTimerContent: some View {
        VStack(spacing: 20) {
            Text(selectedWorkout.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if timer.phase == .idle {
                idlePreviewContent
            } else if timer.phase != .interExerciseRest {
                Text("Exercise \(timer.displayedExerciseNumber) / \(timer.displayedExerciseCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(timer.currentExerciseName)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                phaseCountdown(
                    title: timer.phaseTitle,
                    seconds: timer.secondsRemaining,
                    roundText: "Round \(timer.currentRound) / \(timer.displayedTotalRounds)"
                )
            } else {
                Text("Next: Exercise \(timer.displayedExerciseNumber + 1) / \(timer.displayedExerciseCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                phaseCountdown(
                    title: timer.phaseTitle,
                    seconds: timer.secondsRemaining,
                    roundText: nil
                )
            }
        }
    }

    private var idlePreviewContent: some View {
        let first = selectedWorkout.exercises[0]
        return VStack(spacing: 20) {
            Text("Exercise 1 / \(selectedWorkout.exercises.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(first.name)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            phaseCountdown(
                title: "WORK",
                seconds: first.workDuration,
                roundText: "Round 1 / \(first.rounds)"
            )
        }
    }

    private func phaseCountdown(title: String, seconds: Int, roundText: String?) -> some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title.weight(.semibold))
                .foregroundStyle(phaseColor)
                .accessibilityLabel("Phase \(title)")

            Text("\(seconds)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .accessibilityLabel("\(seconds) seconds remaining")

            if let roundText {
                Text(roundText)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var completedSummary: some View {
        VStack(spacing: 20) {
            Text("Congratulations!")
                .font(.title.weight(.semibold))
                .foregroundStyle(.green)

            Text("WORKOUT COMPLETE")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(selectedWorkout.name)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                statBlock(title: "Workout Time", value: timer.formattedWorkoutTime)
                statBlock(title: "Total Time", value: timer.formattedTotalTime)

                Text("\(timer.completedRoundCount) Rounds")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("\(timer.completedExerciseCount) Exercises")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                calorieSummarySection
            }
            .padding(.top, 8)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var calorieSummarySection: some View {
        if let kcal = CalorieEstimate.estimatedKcal(
            weightKg: userProfile.weightKg,
            workoutTimeSeconds: timer.workoutTimeSeconds,
            totalTimeSeconds: timer.totalTimeSeconds
        ) {
            statBlock(
                title: "Estimated Calories",
                value: CalorieEstimate.formattedEstimate(kcal: kcal)
            )
        } else {
            Text("Add your weight in Settings to estimate calories.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }

    private var phaseColor: Color {
        switch timer.phase {
        case .work, .idle:
            return .orange
        case .rest, .interExerciseRest:
            return .blue
        case .completed:
            return .green
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
