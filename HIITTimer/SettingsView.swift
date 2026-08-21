import SwiftUI

struct SettingsView: View {
    @Bindable var timer: TabataTimer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if !timer.canEditSettings {
                    Text("Reset the workout to change settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                VStack(spacing: 16) {
                    settingRow(
                        title: "WORK",
                        valueText: "\(timer.workDuration)s",
                        value: $timer.workDuration,
                        range: TabataTimer.durationRange
                    )

                    settingRow(
                        title: "REST",
                        valueText: "\(timer.restDuration)s",
                        value: $timer.restDuration,
                        range: TabataTimer.durationRange
                    )

                    settingRow(
                        title: "ROUNDS",
                        valueText: "\(timer.totalRounds)",
                        value: $timer.totalRounds,
                        range: TabataTimer.roundsRange
                    )
                }
                .disabled(!timer.canEditSettings)
                .opacity(timer.canEditSettings ? 1 : 0.45)
                .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func settingRow(
        title: String,
        valueText: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(width: 72, alignment: .leading)

            Text(valueText)
                .font(.body.monospacedDigit())
                .frame(minWidth: 52, alignment: .trailing)

            Spacer()

            Stepper(title, value: value, in: range)
                .labelsHidden()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(valueText)")
    }
}

#Preview {
    SettingsView(timer: TabataTimer())
}
