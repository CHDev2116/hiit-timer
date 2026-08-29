import Foundation

enum DashboardPeriod: String, CaseIterable, Identifiable {
    case last7Days = "Last 7 Days"
    case thisMonth = "This Month"

    var id: String { rawValue }
}

struct DashboardSummary: Equatable {
    let workoutCount: Int
    let activeTimeSeconds: Int
    /// Sum of available calorie estimates; `nil` when no session in the period has kcal data.
    let totalEstimatedKcal: Int?
}

struct DashboardChartBucket: Identifiable, Equatable {
    let id: String
    let label: String
    let activeTimeSeconds: Int
}

enum DashboardAggregation {
    static func filteredSessions(
        _ sessions: [WorkoutSessionRecord],
        period: DashboardPeriod,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [WorkoutSessionRecord] {
        switch period {
        case .last7Days:
            guard let interval = last7DaysInterval(referenceDate: referenceDate, calendar: calendar) else {
                return []
            }
            return sessions.filter { interval.contains($0.completedAt) }
        case .thisMonth:
            guard let interval = monthInterval(referenceDate: referenceDate, calendar: calendar) else {
                return []
            }
            return sessions.filter { interval.contains($0.completedAt) }
        }
    }

    static func summary(
        for sessions: [WorkoutSessionRecord],
        period: DashboardPeriod,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> DashboardSummary {
        let inPeriod = filteredSessions(sessions, period: period, referenceDate: referenceDate, calendar: calendar)
        let activeTime = inPeriod.reduce(0) { $0 + $1.workoutTimeSeconds }
        let kcalValues = inPeriod.compactMap(\.estimatedKcal)
        let totalKcal = kcalValues.isEmpty ? nil : kcalValues.reduce(0, +)

        return DashboardSummary(
            workoutCount: inPeriod.count,
            activeTimeSeconds: activeTime,
            totalEstimatedKcal: totalKcal
        )
    }

    static func chartBuckets(
        for sessions: [WorkoutSessionRecord],
        period: DashboardPeriod,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [DashboardChartBucket] {
        switch period {
        case .last7Days:
            return last7DayBuckets(
                sessions: sessions,
                referenceDate: referenceDate,
                calendar: calendar
            )
        case .thisMonth:
            return monthlyWeekBuckets(
                sessions: sessions,
                referenceDate: referenceDate,
                calendar: calendar
            )
        }
    }

    static func formatActiveTime(_ totalSeconds: Int) -> String {
        guard totalSeconds > 0 else { return "0 min" }
        let minutes = Int((Double(totalSeconds) / 60.0).rounded())
        if minutes < 1 { return "< 1 min" }
        return "\(minutes) min"
    }

    static func formatCaloriesSummary(_ totalKcal: Int?) -> String {
        guard let totalKcal else { return "—" }
        return CalorieEstimate.formattedEstimate(kcal: totalKcal)
    }

    static func activeTimeMinutes(_ seconds: Int) -> Double {
        Double(seconds) / 60.0
    }

    // MARK: - Last 7 days

    private static func last7DaysInterval(
        referenceDate: Date,
        calendar: Calendar
    ) -> DateInterval? {
        let todayStart = calendar.startOfDay(for: referenceDate)
        guard let start = calendar.date(byAdding: .day, value: -6, to: todayStart),
              let end = calendar.date(byAdding: .day, value: 1, to: todayStart) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }

    private static func last7DayBuckets(
        sessions: [WorkoutSessionRecord],
        referenceDate: Date,
        calendar: Calendar
    ) -> [DashboardChartBucket] {
        let todayStart = calendar.startOfDay(for: referenceDate)
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.calendar = calendar
        weekdayFormatter.locale = calendar.locale
        weekdayFormatter.setLocalizedDateFormatFromTemplate("EEE")

        return (0..<7).compactMap { index -> DashboardChartBucket? in
            let offset = index - 6
            guard let dayStart = calendar.date(byAdding: .day, value: offset, to: todayStart),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                return nil
            }

            let activeTime = sessions
                .filter { $0.completedAt >= dayStart && $0.completedAt < dayEnd }
                .reduce(0) { $0 + $1.workoutTimeSeconds }

            let label = weekdayFormatter.string(from: dayStart)
            let id = dayStart.ISO8601Format()

            return DashboardChartBucket(
                id: id,
                label: label,
                activeTimeSeconds: activeTime
            )
        }
    }

    // MARK: - This month (calendar weeks)

    private static func monthInterval(
        referenceDate: Date,
        calendar: Calendar
    ) -> DateInterval? {
        calendar.dateInterval(of: .month, for: referenceDate)
    }

    private static func monthlyWeekBuckets(
        sessions: [WorkoutSessionRecord],
        referenceDate: Date,
        calendar: Calendar
    ) -> [DashboardChartBucket] {
        guard let monthInterval = monthInterval(referenceDate: referenceDate, calendar: calendar),
              let firstWeekStart = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start)?.start else {
            return []
        }

        var buckets: [DashboardChartBucket] = []
        var weekStart = firstWeekStart
        var weekIndex = 1

        while weekStart < monthInterval.end {
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else {
                break
            }

            if weekInterval.end > monthInterval.start && weekInterval.start < monthInterval.end {
                let activeTime = sessions.filter { session in
                    session.completedAt >= monthInterval.start
                        && session.completedAt < monthInterval.end
                        && session.completedAt >= weekInterval.start
                        && session.completedAt < weekInterval.end
                }.reduce(0) { $0 + $1.workoutTimeSeconds }

                buckets.append(
                    DashboardChartBucket(
                        id: "month-week-\(weekIndex)",
                        label: "W\(weekIndex)",
                        activeTimeSeconds: activeTime
                    )
                )
                weekIndex += 1
            }

            guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart),
                  nextWeekStart > weekStart else {
                break
            }
            weekStart = nextWeekStart
        }

        return buckets
    }
}
