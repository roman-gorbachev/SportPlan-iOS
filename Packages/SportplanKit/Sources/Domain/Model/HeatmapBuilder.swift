import Foundation

public enum HeatmapBuilder {
    public static let weekCount = 15
    public static let mondayWeekday = 2

    private static let daysPerWeek = 7

    public static func weekCalendar(_ calendar: Calendar) -> Calendar {
        var weekCalendar = calendar
        weekCalendar.firstWeekday = mondayWeekday
        return weekCalendar
    }

    public static func make(workouts: [FinishedWorkout], today: Date, calendar: Calendar) -> Heatmap {
        let calendar = weekCalendar(calendar)
        let todayStart = calendar.startOfDay(for: today)
        guard
            let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: todayStart)?.start,
            let firstWeekStart = calendar.date(byAdding: .weekOfYear, value: 1 - weekCount, to: currentWeekStart)
        else {
            return Heatmap(weeks: [])
        }
        let workoutsByDay = Dictionary(grouping: workouts) { workout in
            return calendar.startOfDay(for: workout.startedAt)
        }
        let weeks = (0..<weekCount).compactMap { weekIndex -> HeatmapWeek? in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: firstWeekStart) else {
                return nil
            }
            let days = (0..<daysPerWeek).compactMap { dayIndex -> HeatmapDay? in
                guard let date = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) else {
                    return nil
                }
                let dayWorkouts = workoutsByDay[date, default: []].sorted { lhs, rhs in
                    return lhs.startedAt < rhs.startedAt
                }
                return HeatmapDay(
                    date: date,
                    workingSetCount: dayWorkouts.reduce(.zero) { total, workout in
                        return total + workout.workingSetCount
                    },
                    isToday: date == todayStart,
                    isFuture: date > todayStart,
                    workoutIds: dayWorkouts.map(\.id)
                )
            }
            return HeatmapWeek(start: weekStart, days: days)
        }
        return Heatmap(weeks: weeks)
    }
}
