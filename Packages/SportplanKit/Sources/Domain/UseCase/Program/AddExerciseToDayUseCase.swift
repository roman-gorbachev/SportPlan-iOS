import Foundation

public struct AddExerciseToDayUseCase: Sendable {
    private let programRepository: any ProgramRepository
    private let exerciseRepository: any ExerciseRepository

    public init(programRepository: any ProgramRepository, exerciseRepository: any ExerciseRepository) {
        self.programRepository = programRepository
        self.exerciseRepository = exerciseRepository
    }

    public func execute(
        exerciseId: UUID,
        dayId: UUID,
        targets: PlannedExerciseTargets? = nil
    ) async throws -> PlannedExercise {
        guard let exercise = try await exerciseRepository.exercise(id: exerciseId), !exercise.isArchived else {
            throw ProgramError.exerciseUnavailable
        }
        let resolvedTargets = targets ?? PlannedExerciseTargets(defaultsFor: exercise)
        let issues = resolvedTargets.validationIssues(for: exercise.metric)
        guard issues.isEmpty else {
            throw ProgramError.invalidTargets(issues)
        }
        let plannedExercise = PlannedExercise(
            id: UUID(),
            programDayId: dayId,
            exerciseId: exerciseId,
            position: 0,
            targetSets: resolvedTargets.sets,
            targetReps: resolvedTargets.reps,
            restSeconds: resolvedTargets.restSeconds
        )
        return try await programRepository.addPlannedExercise(plannedExercise)
    }
}
