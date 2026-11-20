import Domain
import Foundation

enum HistoryFormatting {
    private static let monthLabelLength = 3
    private static let firstMonth = 1
    private static let secondsPerMinute = 60.0

    static func workoutTitle(_ workout: FinishedWorkout) -> String {
        return String(localized: "format.dotSeparated \(shortDay(workout.startedAt)) \(dayName(workout.workout.programDay))")
    }

    static func dayName(_ day: ProgramDaySnapshot?) -> String {
        guard let day else {
            return String(localized: "history.workout.offPlan")
        }
        guard let label = day.label, !label.isEmpty else {
            return day.name
        }
        return String(localized: "format.dotSeparated \(WorkoutFormatting.dayLabel(label)) \(day.name)")
    }

    static func detailsTitle(_ day: ProgramDaySnapshot?) -> String {
        return day?.name ?? String(localized: "history.details.offPlanTitle")
    }

    static func detailsMeta(_ workout: FinishedWorkout) -> String {
        let date = ExerciseCardFormatting.sessionDate(workout.startedAt)
        let range = String(localized: "history.details.timeRange \(time(workout.startedAt)) \(time(workout.finishedAt))")
        let dateAndTime = String(localized: "format.dotSeparated \(date) \(range)")
        guard let label = workout.workout.programDay?.label, !label.isEmpty else {
            return dateAndTime
        }
        return String(localized: "format.dotSeparated \(dateAndTime) \(WorkoutFormatting.dayLabel(label))")
    }

    static func minutes(_ seconds: Int) -> Int {
        return Int((Double(seconds) / secondsPerMinute).rounded())
    }

    static func workoutMeta(_ workout: FinishedWorkout) -> String {
        let duration = String(localized: "history.workout.minutes \(minutes(workout.durationSeconds))")
        let sets = ProgramFormatting.setsText(workout.workingSetCount)
        return String(localized: "format.dotSeparated \(duration) \(sets)")
    }

    static func shortDay(_ date: Date) -> String {
        let style = Date.VerbatimFormatStyle(
            format: "\(weekday: .abbreviated) \(day: .defaultDigits)",
            locale: AppLocale.current,
            timeZone: .current,
            calendar: .current
        )
        return capitalizedFirst(date.formatted(style))
    }

    static func fullDay(_ date: Date) -> String {
        let style = Date.VerbatimFormatStyle(
            format: "\(weekday: .wide), \(day: .defaultDigits) \(month: .wide)",
            locale: AppLocale.current,
            timeZone: .current,
            calendar: .current
        )
        return capitalizedFirst(date.formatted(style))
    }

    static func time(_ date: Date) -> String {
        return date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(AppLocale.current))
    }

    static func monthTitle(_ date: Date, now: Date, calendar: Calendar) -> String {
        let name = capitalizedFirst(standaloneMonthName(date, calendar: calendar))
        let year = calendar.component(.year, from: date)
        guard year != calendar.component(.year, from: now) else {
            return name
        }
        return String(localized: "history.month.withYear \(name) \(String(year))")
    }

    static func monthLabel(_ date: Date, calendar: Calendar) -> String {
        return String(standaloneMonthName(date, calendar: calendar).prefix(monthLabelLength))
    }

    static func cellAccessibility(_ day: HeatmapDay) -> String {
        let date = ExerciseCardFormatting.recordDate(day.date)
        if day.isFuture {
            return String(localized: "history.heatmap.cell.future \(date)")
        }
        let level = levelText(day.level)
        if day.isToday {
            return String(localized: "history.heatmap.cell.today \(date) \(level)")
        }
        return String(localized: "history.heatmap.cell \(date) \(level)")
    }

    static func levelText(_ level: HeatmapLevel) -> String {
        switch level {
        case .rest:
            return String(localized: "history.heatmap.level.rest")
        case .light:
            return String(localized: "history.heatmap.level.light")
        case .moderate:
            return String(localized: "history.heatmap.level.moderate")
        case .high:
            return String(localized: "history.heatmap.level.high")
        case .peak:
            return String(localized: "history.heatmap.level.peak")
        }
    }

    private static func standaloneMonthName(_ date: Date, calendar: Calendar) -> String {
        var calendar = calendar
        calendar.locale = AppLocale.current
        let symbols = calendar.standaloneMonthSymbols
        let index = calendar.component(.month, from: date) - firstMonth
        guard symbols.indices.contains(index) else {
            return ""
        }
        return symbols[index].lowercased(with: AppLocale.current)
    }

    private static func capitalizedFirst(_ text: String) -> String {
        return text.prefix(1).uppercased(with: AppLocale.current) + text.dropFirst()
    }
}
