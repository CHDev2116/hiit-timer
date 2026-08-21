import SwiftUI

struct ContentView: View {
    @State private var timer = TabataTimer()
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
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
                        timer.start()
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
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(timer: timer)
            }
        }
    }

    private var activeTimerContent: some View {
        VStack(spacing: 32) {
            Text(timer.phaseTitle)
                .font(.title.weight(.semibold))
                .foregroundStyle(phaseColor)
                .accessibilityLabel("Phase \(timer.phaseTitle)")

            Text("\(timer.secondsRemaining)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .accessibilityLabel("\(timer.secondsRemaining) seconds remaining")

            Text("Round \(timer.currentRound) / \(timer.displayedTotalRounds)")
                .font(.title3)
                .foregroundStyle(.secondary)

            if timer.phase == .idle {
                VStack(spacing: 2) {
                    Text("Estimated Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(timer.formattedEstimatedTime)
                        .font(.subheadline.monospacedDigit().weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Estimated Time \(timer.formattedEstimatedTime)")
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
        case .rest:
            return .blue
        case .completed:
            return .green
        }
    }
}

#Preview {
    ContentView()
}
