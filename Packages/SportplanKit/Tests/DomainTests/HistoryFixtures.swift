import Domain
import Foundation

enum HistoryFixtures {
    static let secondsPerHour: TimeInterval = 3_600

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    static func workout(
        exercise: LibraryExercise,
        startedAt: Date,
        sets: [(kilograms: Double, reps: Int, isWarmup: Bool)]
    ) -> FinishedWorkout {
        let workoutId = UUID()
        let item = WorkoutExercise(
            id: UUID(),
            workoutId: workoutId,
            exerciseId: exercise.id,
            position: 0,
            targetSets: nil,
            targetReps: nil,
            restSeconds: exercise.exercise.restSeconds
        )
        let entries = sets.enumerated().map { index, set in
            return DomainFixtures.makeSet(
                workoutExerciseId: item.id,
                position: index,
                kilograms: set.kilograms,
                reps: set.reps,
                isWarmup: set.isWarmup,
                completedAt: startedAt.addingTimeInterval(TimeInterval(index))
            )
        }
        return FinishedWorkout(
            workout: Workout(
                id: workoutId,
                programDay: nil,
                startedAt: startedAt,
                finishedAt: startedAt.addingTimeInterval(secondsPerHour),
                note: nil,
                rest: nil
            ),
            programName: nil,
            exercises: [FinishedWorkoutExercise(workoutExercise: item, exercise: exercise, sets: entries)]
        )
    }

    static func working(_ count: Int, kilograms: Double = 60, reps: Int = 8) -> [(kilograms: Double, reps: Int, isWarmup: Bool)] {
        return Array(repeating: (kilograms: kilograms, reps: reps, isWarmup: false), count: count)
    }

    static func log(_ workout: FinishedWorkout, in repository: FakeWorkoutRepository) async throws {
        var active = workout.workout
        active.finishedAt = nil
        try await repository.start(
            active,
            exercises: workout.exercises.map(\.workoutExercise),
            sets: workout.exercises.flatMap(\.sets)
        )
        try await repository.finish(workoutId: workout.id, at: workout.finishedAt)
    }
}
