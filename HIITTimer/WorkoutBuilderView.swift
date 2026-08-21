import SwiftUI

/// Phase C-2: inline editable WORK / REST / ROUNDS per exercise.
/// Count control (C-1) and scroll layout (B) unchanged.
struct WorkoutBuilderView: View {
    private static let exerciseCountRange = 1...20

    @State private var exercises: [Exercise] = [Exercise.makeDefault(index: 1)]
    @State private var restBetweenExercises = 60
    @State private var showingTimer = false
    @State private var workoutToRun: [Exercise] = []
    @State private var restBetweenToRun = 60

    private var formattedEstimatedTime: String {
        WorkoutEstimate.formatDuration(
            WorkoutEstimate.totalSeconds(
                for: exercises,
                restBetweenExercises: restBetweenExercises
            )
        )
    }

    private var canStartWorkout: Bool {
        !exercises.isEmpty
            && exercises.allSatisfy {
                !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    Stepper(
                        "Number of Exercises: \(exercises.count)",
                        value: Binding(
                            get: { exercises.count },
                            set: { setExerciseCount($0) }
                        ),
                        in: Self.exerciseCountRange
                    )
                    .padding(.horizontal, 4)

                    Stepper(
                        "Rest Between Exercises: \(restBetweenExercises)s",
                        value: $restBetweenExercises,
                        in: Exercise.durationRange
                    )
                    .padding(.horizontal, 4)

                    ForEach(Array(exercises.indices), id: \.self) { index in
                        exerciseCard(index: index)
                            .id(exercises[index].id)
                    }

                    VStack(spacing: 8) {
                        Text("Estimated Time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formattedEstimatedTime)
                            .font(.title2.monospacedDigit().weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Button("START") {
                        workoutToRun = exercises
                        restBetweenToRun = restBetweenExercises
                        showingTimer = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(!canStartWorkout)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Workout Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingTimer) {
                ContentView(
                    exercises: workoutToRun,
                    restBetweenExercises: restBetweenToRun
                )
            }
        }
    }

    private func exerciseCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Exercise \(index + 1)")
                .font(.headline)

            labeledRow("Name", exercises[index].name)

            stepperRow(
                title: "WORK",
                value: $exercises[index].workDuration,
                range: Exercise.durationRange,
                unitSuffix: "s"
            )

            stepperRow(
                title: "REST",
                value: $exercises[index].restDuration,
                range: Exercise.durationRange,
                unitSuffix: "s"
            )

            stepperRow(
                title: "ROUNDS",
                value: $exercises[index].rounds,
                range: Exercise.roundsRange
            )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text("\(title):")
                .foregroundStyle(.secondary)
            Text(value)
                .monospacedDigit()
            Spacer(minLength: 0)
        }
        .font(.body)
    }

    private func stepperRow(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        unitSuffix: String = ""
    ) -> some View {
        let clamped = Binding(
            get: { value.wrappedValue },
            set: { newValue in
                value.wrappedValue = min(range.upperBound, max(range.lowerBound, newValue))
            }
        )

        return HStack {
            Text("\(title):")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            HStack(spacing: 2) {
                TextField("", value: clamped, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.body.monospacedDigit())
                    .frame(minWidth: 40, alignment: .trailing)

                if !unitSuffix.isEmpty {
                    Text(unitSuffix)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }

            Spacer(minLength: 8)

            Stepper(title, value: clamped, in: range)
                .labelsHidden()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value.wrappedValue)\(unitSuffix)")
    }

    /// Grow/shrink from the end only. Prefix exercises keep their values and IDs.
    private func setExerciseCount(_ count: Int) {
        let clamped = min(
            Self.exerciseCountRange.upperBound,
            max(Self.exerciseCountRange.lowerBound, count)
        )

        if clamped > exercises.count {
            let start = exercises.count + 1
            for index in start...clamped {
                exercises.append(Exercise.makeDefault(index: index))
            }
        } else if clamped < exercises.count {
            exercises.removeLast(exercises.count - clamped)
        }
    }
}

#Preview {
    WorkoutBuilderView()
}
