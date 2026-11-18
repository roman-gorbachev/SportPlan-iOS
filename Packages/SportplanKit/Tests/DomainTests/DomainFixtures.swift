import Domain
import Foundation

enum DomainFixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

    static func makeEquipment(name: String = "Олимпийский гриф", kind: EquipmentKind = .barbell, isArchived: Bool = false) -> Equipment {
        return Equipment(
            id: UUID(),
            name: name,
            kind: kind,
            baseWeight: kind.hasBaseWeight ? Weight(kilograms: 20) : .zero,
            weightStep: Weight(kilograms: 2.5),
            isArchived: isArchived,
            createdAt: referenceDate
        )
    }

    static func makeExercise(name: String, load: ExerciseLoad, metric: ExerciseMetric = .weightReps) -> Exercise {
        return Exercise(
            id: UUID(),
            name: name,
            description: nil,
            load: load,
            metric: metric,
            restSeconds: Exercise.defaultRestSeconds,
            isArchived: false,
            createdAt: referenceDate
        )
    }
}

extension DomainFixtures {
    static func makeLibraryExercise(
        name: String = "Жим лёжа",
        kind: EquipmentKind? = .barbell,
        metric: ExerciseMetric = .weightReps
    ) -> LibraryExercise {
        let equipment = kind.map { kind in
            return makeEquipment(kind: kind)
        }
        let load: ExerciseLoad = equipment.map { equipment in
            return ExerciseLoad.equipment(id: equipment.id)
        } ?? .bodyweight
        return LibraryExercise(exercise: makeExercise(name: name, load: load, metric: metric), equipment: equipment)
    }

    static func makeSet(
        workoutExerciseId: UUID = UUID(),
        position: Int,
        kilograms: Double,
        reps: Int?,
        durationSeconds: Int? = nil,
        isWarmup: Bool = false,
        completedAt: Date? = referenceDate
    ) -> SetEntry {
        return SetEntry(
            id: UUID(),
            workoutExerciseId: workoutExerciseId,
            position: position,
            weight: Weight(kilograms: kilograms),
            reps: reps,
            durationSeconds: durationSeconds,
            isWarmup: isWarmup,
            startedAt: nil,
            completedAt: completedAt
        )
    }

    static func makeActiveExercise(
        exercise: LibraryExercise,
        sets: [SetEntry],
        previousSets: [SetEntry] = [],
        targetReps: RepRange? = RepRange(min: 8, max: 12)
    ) -> ActiveWorkoutExercise {
        let workoutExercise = WorkoutExercise(
            id: sets.first?.workoutExerciseId ?? UUID(),
            workoutId: UUID(),
            exerciseId: exercise.id,
            position: 0,
            targetSets: sets.count,
            targetReps: targetReps,
            restSeconds: Exercise.defaultRestSeconds
        )
        return ActiveWorkoutExercise(workoutExercise: workoutExercise, exercise: exercise, sets: sets, previousSets: previousSets)
    }
}
