import SwiftUI

// MARK: - Workout Library (Settings root)

/// Lists saved workouts, selects the timer workout, and opens the editor.
struct WorkoutLibraryView: View {
    var canEdit: Bool = true

    @Environment(\.dismiss) private var dismiss
    @State private var library = WorkoutLibrary.load()
    @State private var editorRoute: EditorRoute?
    @State private var workoutPendingDeletion: SavedWorkout?

    private enum EditorRoute: Identifiable, Hashable {
        case create
        case edit(UUID)

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let uuid): return uuid.uuidString
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if canEdit {
                    libraryList
                } else {
                    VStack(spacing: 16) {
                        Text("Reset the workout to change settings.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 24)

                        libraryList
                            .disabled(true)
                            .opacity(0.45)
                    }
                }
            }
            .navigationTitle("Workout Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("New Workout") {
                        editorRoute = .create
                    }
                    .disabled(!canEdit)
                }
            }
            .navigationDestination(item: $editorRoute) { route in
                editor(for: route)
            }
            .alert(
                deleteAlertTitle,
                isPresented: Binding(
                    get: { workoutPendingDeletion != nil },
                    set: { if !$0 { workoutPendingDeletion = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) {
                    workoutPendingDeletion = nil
                }
                Button("Delete", role: .destructive) {
                    confirmDelete()
                }
            } message: {
                Text("This workout will be permanently deleted.")
            }
        }
    }

    private var deleteAlertTitle: String {
        if let name = workoutPendingDeletion?.name {
            return "Delete \"\(name)\"?"
        }
        return "Delete Workout?"
    }

    private var libraryList: some View {
        List {
            Section {
                ForEach(library.workouts) { workout in
                    workoutRow(workout)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                workoutPendingDeletion = workout
                            }
                            .disabled(!canEdit)
                        }
                }
            } footer: {
                Text("Tap a workout to select it for the timer. Use Edit to change its configuration. Swipe left to delete.")
            }
        }
    }

    private func workoutRow(_ workout: SavedWorkout) -> some View {
        HStack(spacing: 12) {
            Button {
                selectWorkout(workout)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("\(workout.exercises.count) exercises")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    if workout.id == library.selectedWorkoutID {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button("Edit") {
                editorRoute = .edit(workout.id)
            }
            .buttonStyle(.bordered)
            .disabled(!canEdit)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func editor(for route: EditorRoute) -> some View {
        switch route {
        case .create:
            WorkoutEditorView(
                draft: SavedWorkout.makeDefault(name: "New Workout"),
                isNew: true,
                library: $library
            )
        case .edit(let id):
            if let workout = library.workouts.first(where: { $0.id == id }) {
                WorkoutEditorView(
                    draft: workout,
                    isNew: false,
                    library: $library
                )
            } else {
                Text("Workout not found.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func selectWorkout(_ workout: SavedWorkout) {
        guard canEdit else { return }
        library.select(workout.id)
        library.save()
    }

    private func confirmDelete() {
        guard let workout = workoutPendingDeletion else { return }
        workoutPendingDeletion = nil
        library.delete(id: workout.id)
        library.save()
        if case .edit(let id) = editorRoute, id == workout.id {
            editorRoute = nil
        }
    }
}

// MARK: - Workout Editor

/// Creates or edits one workout draft. Library is unchanged until Save Workout.
struct WorkoutEditorView: View {
    private static let exerciseCountRange = Exercise.countRange

    let isNew: Bool

    @Binding var library: WorkoutLibrary
    @Environment(\.dismiss) private var dismiss

    @State private var draft: SavedWorkout

    init(draft: SavedWorkout, isNew: Bool, library: Binding<WorkoutLibrary>) {
        self.isNew = isNew
        self._library = library
        // Snapshot so edits never mutate the library entry until Save.
        self._draft = State(initialValue: draft)
    }

    private var formattedEstimatedTime: String {
        WorkoutEstimate.formatDuration(
            WorkoutEstimate.totalSeconds(
                for: draft.exercises,
                restBetweenExercises: draft.restBetweenExercises
            )
        )
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.exercises.isEmpty
            && draft.exercises.allSatisfy {
                !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    workoutNameField

                    Stepper(
                        "Number of Exercises: \(draft.exercises.count)",
                        value: Binding(
                            get: { draft.exercises.count },
                            set: { setExerciseCount($0) }
                        ),
                        in: Self.exerciseCountRange
                    )
                    .padding(.horizontal, 4)

                    editableValueRow(
                        title: "REST BETWEEN EXERCISES",
                        value: $draft.restBetweenExercises,
                        range: Exercise.durationRange,
                        unitSuffix: "s"
                    )

                    ForEach(Array(draft.exercises.indices), id: \.self) { index in
                        exerciseCard(index: index)
                            .id(draft.exercises[index].id)
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
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)

            saveWorkoutBar
        }
        .navigationTitle(isNew ? "New Workout" : "Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var saveWorkoutBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button("Save Workout") {
                saveDraft()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(!canSave)
            .padding()
            .background(Color(.systemBackground))
        }
    }

    private var workoutNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WORKOUT NAME")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Workout name", text: $draft.name)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 1)
                )
        }
    }

    private func exerciseCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Exercise \(index + 1)")
                .font(.headline)

            labeledRow("Name", draft.exercises[index].name)

            editableValueRow(
                title: "WORK",
                value: $draft.exercises[index].workDuration,
                range: Exercise.durationRange,
                unitSuffix: "s"
            )

            editableValueRow(
                title: "REST",
                value: $draft.exercises[index].restDuration,
                range: Exercise.durationRange,
                unitSuffix: "s"
            )

            editableValueRow(
                title: "ROUNDS",
                value: $draft.exercises[index].rounds,
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

    private func editableValueRow(
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

        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    clamped.wrappedValue = max(range.lowerBound, clamped.wrappedValue - 1)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .disabled(clamped.wrappedValue <= range.lowerBound)
                .accessibilityLabel("Decrease \(title)")

                HStack(spacing: 2) {
                    TextField("", value: clamped, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.body.monospacedDigit())
                        .frame(minWidth: 44)

                    if !unitSuffix.isEmpty {
                        Text(unitSuffix)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 1)
                )
                .accessibilityLabel("\(title) \(value.wrappedValue)\(unitSuffix)")

                Button {
                    clamped.wrappedValue = min(range.upperBound, clamped.wrappedValue + 1)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .disabled(clamped.wrappedValue >= range.upperBound)
                .accessibilityLabel("Increase \(title)")
            }
        }
    }

    private func setExerciseCount(_ count: Int) {
        let clamped = min(
            Self.exerciseCountRange.upperBound,
            max(Self.exerciseCountRange.lowerBound, count)
        )

        if clamped > draft.exercises.count {
            let start = draft.exercises.count + 1
            for index in start...clamped {
                draft.exercises.append(Exercise.makeDefault(index: index))
            }
        } else if clamped < draft.exercises.count {
            draft.exercises.removeLast(draft.exercises.count - clamped)
        }
    }

    private func saveDraft() {
        guard canSave else { return }
        if isNew {
            library.insert(draft)
        } else {
            library.update(draft)
        }
        library.save()
        dismiss()
    }
}

#Preview("Library") {
    WorkoutLibraryView()
}

#Preview("Editor") {
    NavigationStack {
        WorkoutEditorView(
            draft: SavedWorkout.makeDefault(),
            isNew: true,
            library: .constant(WorkoutLibrary.default)
        )
    }
}
