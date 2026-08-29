import Charts
import SwiftUI

struct DashboardView: View {
    @State private var history = WorkoutHistory.load()
    @State private var period: DashboardPeriod = .last7Days

    private var summary: DashboardSummary {
        DashboardAggregation.summary(for: history.sessions, period: period)
    }

    private var chartBuckets: [DashboardChartBucket] {
        DashboardAggregation.chartBuckets(for: history.sessions, period: period)
    }

    var body: some View {
        Group {
            if history.sessions.isEmpty {
                emptyState
            } else {
                dashboardContent
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            history = WorkoutHistory.load()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Activity Yet", systemImage: "chart.bar")
        } description: {
            Text("Complete a workout to see your activity here.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Picker("Period", selection: $period) {
                    ForEach(DashboardPeriod.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                summarySection

                chartSection
            }
            .padding()
        }
    }

    private var summarySection: some View {
        HStack(spacing: 0) {
            summaryTile(
                title: "WORKOUTS",
                value: "\(summary.workoutCount)"
            )
            summaryTile(
                title: "ACTIVE TIME",
                value: DashboardAggregation.formatActiveTime(summary.activeTimeSeconds)
            )
            summaryTile(
                title: "CALORIES",
                value: DashboardAggregation.formatCaloriesSummary(summary.totalEstimatedKcal)
            )
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func summaryTile(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Workout Time")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Chart(chartBuckets) { bucket in
                BarMark(
                    x: .value("Period", bucket.label),
                    y: .value("Minutes", DashboardAggregation.activeTimeMinutes(bucket.activeTimeSeconds))
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text("\(Int(minutes.rounded()))m")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 220)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityLabel("Active workout time chart")
        }
    }
}

#Preview("Empty") {
    NavigationStack {
        DashboardView()
    }
}
