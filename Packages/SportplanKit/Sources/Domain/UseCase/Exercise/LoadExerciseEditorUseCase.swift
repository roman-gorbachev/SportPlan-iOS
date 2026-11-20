import Foundation

public struct LoadExerciseEditorUseCase: Sendable {
    private let exerciseRepository: any ExerciseRepository
    private let loadKindResolver: ExerciseLoadKindResolver

    public init(exerciseRepository: any ExerciseRepository, equipmentRepository: any EquipmentRepository) {
        self.exerciseRepository = exerciseRepository
        self.loadKindResolver = ExerciseLoadKindResolver(equipmentRepository: equipmentRepository)
    }

    public func execute(exerciseId: UUID) async throws -> ExerciseEditorSnapshot {
        guard let exercise = try await exerciseRepository.exercise(id: exerciseId) else {
            throw ExerciseError.notFound
        }
        return ExerciseEditorSnapshot(
            exercise: exercise,
            loadKind: try await loadKindResolver.loadKind(of: exercise),
            hasCompletedSets: try await exerciseRepository.hasCompletedSets(exerciseId: exerciseId),
            programDayCount: try await exerciseRepository.programDayCount(usingExerciseId: exerciseId)
        )
    }
}
