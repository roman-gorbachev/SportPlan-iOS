import Domain
import Foundation

enum WorkoutFormatting {
    private static let listedExerciseLimit = 3

    static func shortDate(_ date: Date) -> String {
        let style = Date.VerbatimFormatStyle(
            format: "\(weekday: .abbreviated) \(day: .twoDigits).\(month: .twoDigits)",
            locale: AppLocale.current,
            timeZone: .current,
            calendar: .current
        )
        return date.formatted(style).lowercased(with: AppLocale.current)
    }

    static func lastWorkoutText(_ date: Date?) -> String {
        guard let date else {
            return String(localized: "workout.never")
        }
        return shortDate(date)
    }

    static func dayTitle(_ day: ProgramDay) -> String {
        guard let label = day.label else {
            return day.name
        }
        return String(localized: "format.dotSeparated \(dayLabel(label)) \(day.name)")
    }

    static func dayLabel(_ label: String) -> String {
        return String(localized: "workout.day.label \(label)")
    }

    static func exerciseList(_ names: [String]) -> String {
        guard !names.isEmpty else {
            return String(localized: "workout.start.exercises.none")
        }
        let listed = names.prefix(listedExerciseLimit).joined(separator: String(localized: "format.listSeparator"))
        let remaining = names.count - listedExerciseLimit
        guard remaining > 0 else {
            return listed
        }
        return String(localized: "workout.start.exercises.more \(listed) \(remaining)")
    }

    static func duration(seconds: Int) -> String {
        return RestFormatting.clock(seconds: seconds)
    }

    static func setSummary(_ entry: SetEntry, exercise: LibraryExercise) -> String {
        switch exercise.metric {
        case .duration:
            return entry.durationSeconds.map(duration(seconds:)) ?? String(localized: "workout.set.noValue")
        case .weightReps:
            let reps = entry.reps?.formatted() ?? String(localized: "workout.set.noValue")
            guard let weight = weightText(entry.weight, exercise: exercise) else {
                return reps
            }
            return String(localized: "workout.set.value \(weight) \(reps)")
        }
    }

    static func weightText(_ weight: Weight, exercise: LibraryExercise) -> String? {
        guard exercise.equipment == nil else {
            return WeightFormatting.kilograms(weight)
        }
        guard weight > .zero else {
            return nil
        }
        return String(localized: "workout.set.addedWeight \(WeightFormatting.kilograms(weight))")
    }
}
