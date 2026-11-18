import Foundation

public struct StartWorkoutFromDayUseCase: Sendable {
    private let workoutRepository: any WorkoutRepository
    private let programRepository: any ProgramRepository
    private let now: @Sendable () -> Date

    public init(
        workoutRepository: any WorkoutRepository,
        programRepository: any ProgramRepository,
        now: @escaping @Sendable () -> Date
    ) {
        self.workoutRepository = workoutRepository
        self.programRepository = programRepository
        self.now = now
    }

    public func execute(dayId: UUID) async throws {
        guard try await workoutRepository.activeWorkout() == nil else {
            throw WorkoutError.alreadyActive
        }
        guard let detail = try await programRepository.day(id: dayId) else {
            throw WorkoutError.notFound
        }
        let workout = Workout(
            id: UUID(),
            programDay: ProgramDaySnapshot(programDayId: detail.day.id, name: detail.day.name, label: detail.day.label),
            startedAt: now(),
            finishedAt: nil,
            note: nil,
            rest: nil
        )
        var exercises: [WorkoutExercise] = []
        var sets: [SetEntry] = []
        for (position, item) in detail.exercises.enumerated() {
            let planned = item.plannedExercise
            let workoutExercise = WorkoutExercise(
                id: UUID(),
                workoutId: workout.id,
                exerciseId: item.exercise.id,
                position: position,
                targetSets: planned.targetSets,
                targetReps: planned.targetReps,
                restSeconds: planned.restSeconds
            )
            let previousSets = try await workoutRepository.previousSets(exerciseId: item.exercise.id)
            exercises.append(workoutExercise)
            sets += WorkoutSetPlanner.plannedSets(
                for: item.exercise,
                workoutExerciseId: workoutExercise.id,
                targetSets: planned.targetSets,
                targetReps: planned.targetReps,
                previousSets: previousSets
            )
        }
        try await workoutRepository.start(workout, exercises: exercises, sets: sets)
    }
}
