import SwiftUI

/// Configure weight used for post-workout calorie estimates.
struct PersonalProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profile: UserProfile

    @State private var weightText: String

    init(profile: Binding<UserProfile>) {
        _profile = profile
        if let weight = profile.wrappedValue.weightKg {
            _weightText = State(initialValue: Self.formatWeight(weight))
        } else {
            _weightText = State(initialValue: "")
        }
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Text("Weight")
                    Spacer()
                    TextField("—", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.body.monospacedDigit())
                        .frame(maxWidth: 120)
                    Text("kg")
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Used to estimate calories after your workouts. Stored only on this device.")
            }
        }
        .navigationTitle("Calorie Estimate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveAndDismiss()
                }
            }
        }
    }

    private func saveAndDismiss() {
        let trimmed = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            profile.weightKg = nil
        } else if let value = Double(trimmed.replacingOccurrences(of: ",", with: ".")),
                  value > 0 {
            profile.weightKg = value
        }
        profile = profile.sanitized()
        profile.save()
        dismiss()
    }

    private static func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}

#Preview {
    NavigationStack {
        PersonalProfileView(profile: .constant(UserProfile(weightKg: 70)))
    }
}
