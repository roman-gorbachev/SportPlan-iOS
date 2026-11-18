import Foundation

public struct UpdatePlannedExerciseTargetsUseCase: Sendable {
    private let programRepository: any ProgramRepository
    private let exerciseRepository: any ExerciseRepository

    public init(programRepository: any ProgramRepository, exerciseRepository: any ExerciseRepository) {
        self.programRepository = programRepository
        self.exerciseRepository = exerciseRepository
    }

    public func execute(id: UUID, targets: PlannedExerciseTargets) async throws {
        guard
            let plannedExercise = try await programRepository.plannedExercise(id: id),
            let exercise = try await exerciseRepository.exercise(id: plannedExercise.exerciseId)
        else {
            throw ProgramError.notFound
        }
        let issues = targets.validationIssues(for: exercise.metric)
        guard issues.isEmpty else {
            throw ProgramError.invalidTargets(issues)
        }
        try await programRepository.updateTargets(plannedExerciseId: id, targets: targets)
    }
}
