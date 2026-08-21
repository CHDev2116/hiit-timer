import SwiftUI

struct ContentView: View {
    /// Workout plan snapped when navigating from the builder.
    let exercises: [Exercise]
    let restBetweenExercises: Int

    @State private var timer = TabataTimer()
    @State private var didAutoStart = false

    init(
        exercises: [Exercise] = [Exercise.makeDefault(index: 1)],
        restBetweenExercises: Int = 60
    ) {
        self.exercises = exercises
        self.restBetweenExercises = restBetweenExercises
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
                    timer.start(
                        exercises: exercises,
                        restBetweenExercises: restBetweenExercises
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
        .onAppear {
            guard !didAutoStart else { return }
            didAutoStart = true
            timer.start(
                exercises: exercises,
                restBetweenExercises: restBetweenExercises
            )
        }
        .onDisappear {
            timer.pause()
        }
    }

    private var activeTimerContent: some View {
        VStack(spacing: 20) {
            if timer.phase != .interExerciseRest {
                Text("Exercise \(timer.displayedExerciseNumber) / \(timer.displayedExerciseCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(timer.currentExerciseName)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
            } else {
                Text("Next: Exercise \(timer.displayedExerciseNumber + 1) / \(timer.displayedExerciseCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(timer.phaseTitle)
                .font(.title.weight(.semibold))
                .foregroundStyle(phaseColor)
                .accessibilityLabel("Phase \(timer.phaseTitle)")

            Text("\(timer.secondsRemaining)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .accessibilityLabel("\(timer.secondsRemaining) seconds remaining")

            if timer.phase != .interExerciseRest {
                Text("Round \(timer.currentRound) / \(timer.displayedTotalRounds)")
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

            VStack(spacing: 16) {
                statBlock(title: "Workout Time", value: timer.formattedWorkoutTime)
                statBlock(title: "Total Time", value: timer.formattedTotalTime)

                Text("\(timer.completedRoundCount) Rounds")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("\(timer.completedExerciseCount) Exercises")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
        .accessibilityElement(children: .combine)
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
        ContentView(exercises: [
            Exercise.makeDefault(index: 1),
            Exercise(
                id: UUID(),
                name: "Exercise 2",
                workDuration: 25,
                restDuration: 15,
                rounds: 2
            ),
        ], restBetweenExercises: 60)
    }
}
