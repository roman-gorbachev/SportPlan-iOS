import Domain
import Foundation
import GRDB
@testable import sportplan

nonisolated enum DatabaseFixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)
    static let restLength: TimeInterval = 90

    static func makeDatabase() throws -> AppDatabase {
        return try AppDatabase(DatabaseQueue())
    }

    static func makeEquipment() -> Equipment {
        return Equipment(
            id: UUID(),
            name: "Олимпийский гриф",
            kind: .barbell,
            baseWeight: Weight(kilograms: 20),
            weightStep: Weight(kilograms: 2.5),
            isArchived: false,
            createdAt: referenceDate
        )
    }

    static func makeExercise(load: ExerciseLoad) -> Exercise {
        return Exercise(
            id: UUID(),
            name: "Жим лёжа",
            description: "Лопатки сведены",
            load: load,
            metric: .weightReps,
            restSeconds: Exercise.defaultRestSeconds,
            isArchived: false,
            createdAt: referenceDate
        )
    }

    static func makeProgram() -> Program {
        return Program(id: UUID(), name: "Сила 3×", position: 0, createdAt: referenceDate)
    }

    static func makeDay(programId: UUID) -> ProgramDay {
        return ProgramDay(id: UUID(), programId: programId, name: "Грудь и трицепс", label: "A", position: 0)
    }

    static func makePlannedExercise(dayId: UUID, exerciseId: UUID) -> PlannedExercise {
        return PlannedExercise(
            id: UUID(),
            programDayId: dayId,
            exerciseId: exerciseId,
            position: 0,
            targetSets: 3,
            targetReps: RepRange(min: 8, max: 12),
            restSeconds: Exercise.defaultRestSeconds
        )
    }

    static func makeWorkout(day: ProgramDay?, finishedAt: Date?) -> Workout {
        return Workout(
            id: UUID(),
            programDay: day.map { day in
                return ProgramDaySnapshot(programDayId: day.id, name: day.name, label: day.label)
            },
            startedAt: referenceDate,
            finishedAt: finishedAt,
            note: "Плечо не беспокоило",
            rest: RestPeriod(startedAt: referenceDate, endsAt: referenceDate.addingTimeInterval(restLength))
        )
    }

    static func makeWorkoutExercise(workoutId: UUID, exerciseId: UUID) -> WorkoutExercise {
        return WorkoutExercise(
            id: UUID(),
            workoutId: workoutId,
            exerciseId: exerciseId,
            position: 0,
            targetSets: 3,
            targetReps: RepRange(min: 8, max: 12),
            restSeconds: Exercise.defaultRestSeconds
        )
    }

    static func makeSet(workoutExerciseId: UUID) -> SetEntry {
        return SetEntry(
            id: UUID(),
            workoutExerciseId: workoutExerciseId,
            position: 0,
            weight: Weight(kilograms: 62.5),
            reps: 8,
            durationSeconds: nil,
            isWarmup: false,
            startedAt: nil,
            completedAt: referenceDate
        )
    }
}
