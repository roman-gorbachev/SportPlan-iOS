import Domain
import Foundation

enum ProgramFormatting {
    static func dayFullTitle(_ day: ProgramDay) -> String {
        guard let label = day.label else {
            return day.name
        }
        return String(localized: "format.dotSeparated \(label) \(day.name)")
    }

    static func dayShortTitle(_ day: ProgramDay) -> String {
        return day.label ?? day.name
    }

    static func daySubtitle(programName: String, day: ProgramDay) -> String {
        guard let label = day.label else {
            return programName
        }
        return String(localized: "format.dotSeparated \(programName) \(label)")
    }

    static func repsText(_ reps: RepRange) -> String {
        guard reps.min != reps.max else {
            return reps.min.formatted()
        }
        return String(localized: "plannedExercise.reps.range \(reps.min) \(reps.max)")
    }

    static func setsText(_ sets: Int) -> String {
        return String(localized: "plannedExercise.sets.count \(sets)")
    }

    static func targetText(_ targets: PlannedExerciseTargets) -> String {
        guard let reps = targets.reps else {
            return setsText(targets.sets)
        }
        return String(localized: "plannedExercise.target \(targets.sets) \(repsText(reps))")
    }

    static func targetSpokenText(_ targets: PlannedExerciseTargets) -> String {
        let sets = setsText(targets.sets)
        guard let reps = targets.reps else {
            return sets
        }
        return String(localized: "plannedExercise.target.spoken \(sets) \(repsText(reps))")
    }

    static func detailText(_ item: PlannedExerciseItem) -> String {
        let rest = String(localized: "plannedExercise.rest \(RestFormatting.clock(seconds: item.plannedExercise.restSeconds))")
        if item.exercise.exercise.metric == .duration {
            let timed = String(localized: "plannedExercise.timed")
            return String(localized: "format.dotSeparated \(timed) \(rest)")
        }
        let load = item.exercise.equipment?.name ?? String(localized: "plannedExercise.bodyweight")
        return String(localized: "format.dotSeparated \(rest) \(load)")
    }
}
