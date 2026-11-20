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
        if let reps = targets.reps {
            return String(localized: "plannedExercise.target \(targets.sets) \(repsText(reps))")
        }
        if let durationSeconds = targets.durationSeconds {
            return String(localized: "plannedExercise.target \(targets.sets) \(RestFormatting.clock(seconds: durationSeconds))")
        }
        return setsText(targets.sets)
    }

    static func targetSpokenText(_ targets: PlannedExerciseTargets) -> String {
        let sets = setsText(targets.sets)
        if let reps = targets.reps {
            return String(localized: "plannedExercise.target.spoken \(sets) \(repsText(reps))")
        }
        if let durationSeconds = targets.durationSeconds {
            return String(localized: "plannedExercise.target.duration.spoken \(sets) \(RestFormatting.spoken(seconds: durationSeconds))")
        }
        return sets
    }

    static func detailText(_ item: PlannedExerciseItem) -> String {
        let rest = String(localized: "plannedExercise.rest \(RestFormatting.clock(seconds: item.plannedExercise.restSeconds))")
        if item.exercise.exercise.metric == .duration {
            let timed = String(localized: "plannedExercise.timed")
            return String(localized: "format.dotSeparated \(timed) \(rest)")
        }
        let load = item.exercise.equipment?.name ?? String(localized: "plannedExercise.bodyweight")
        let restAndLoad = String(localized: "format.dotSeparated \(rest) \(load)")
        guard let startWeight = item.plannedExercise.startWeight else {
            return restAndLoad
        }
        let start = String(localized: "plannedExercise.startWeight \(WeightFormatting.kilograms(startWeight))")
        return String(localized: "format.dotSeparated \(start) \(restAndLoad)")
    }
}
