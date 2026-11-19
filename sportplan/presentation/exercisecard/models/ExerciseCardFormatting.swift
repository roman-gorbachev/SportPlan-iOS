import Domain
import Foundation

enum ExerciseCardFormatting {
    private static let gramsPerKilogram = 1000.0
    private static let maximumKilogramFractionDigits = 1

    static func value(_ value: Int, kind: ExerciseCardValueKind) -> String {
        return axisValue(plotValue(value, kind: kind), kind: kind)
    }

    static func plotValue(_ value: Int, kind: ExerciseCardValueKind) -> Double {
        switch kind {
        case .kilograms:
            return Double(value) / gramsPerKilogram
        case .reps, .duration:
            return Double(value)
        }
    }

    static func axisValue(_ plotValue: Double, kind: ExerciseCardValueKind) -> String {
        switch kind {
        case .kilograms:
            return plotValue.formatted(
                .number.grouping(.never).precision(.fractionLength(0...maximumKilogramFractionDigits)).locale(AppLocale.current)
            )
        case .reps:
            return Int(plotValue.rounded()).formatted()
        case .duration:
            return WorkoutFormatting.duration(seconds: Int(plotValue.rounded()))
        }
    }

    static func unit(_ kind: ExerciseCardValueKind) -> String {
        switch kind {
        case .kilograms:
            return String(localized: "workout.set.kg")
        case .reps:
            return String(localized: "exerciseCard.unit.reps")
        case .duration:
            return String(localized: "workout.set.minutes")
        }
    }

    static func valueWithUnit(_ value: Int, kind: ExerciseCardValueKind) -> String {
        return String(localized: "exerciseCard.valueWithUnit \(self.value(value, kind: kind)) \(unit(kind))")
    }

    static func delta(_ delta: Int, kind: ExerciseCardValueKind) -> String {
        let magnitude = value(abs(delta), kind: kind)
        guard delta != 0 else {
            return magnitude
        }
        return delta > 0
            ? String(localized: "exerciseCard.delta.up \(magnitude)")
            : String(localized: "exerciseCard.delta.down \(magnitude)")
    }

    static func recordDate(_ date: Date) -> String {
        let style = Date.VerbatimFormatStyle(
            format: "\(day: .defaultDigits) \(month: .wide)",
            locale: AppLocale.current,
            timeZone: .current,
            calendar: .current
        )
        return date.formatted(style)
    }

    static func sessionDate(_ date: Date) -> String {
        let style = Date.VerbatimFormatStyle(
            format: "\(weekday: .abbreviated) \(day: .defaultDigits) \(month: .wide)",
            locale: AppLocale.current,
            timeZone: .current,
            calendar: .current
        )
        let text = date.formatted(style)
        return text.prefix(1).uppercased(with: AppLocale.current) + text.dropFirst()
    }
}
