import Foundation

public struct AddExerciseToWorkoutUseCase: Sendable {
    private let workoutRepository: any WorkoutRepository
    private let exerciseRepository: any ExerciseRepository
    private let equipmentRepository: any EquipmentRepository

    public init(
        workoutRepository: any WorkoutRepository,
        exerciseRepository: any ExerciseRepository,
        equipmentRepository: any EquipmentRepository
    ) {
        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
        self.equipmentRepository = equipmentRepository
    }

    public func execute(exerciseId: UUID) async throws {
        guard let active = try await workoutRepository.activeWorkout() else {
            throw WorkoutError.noActiveWorkout
        }
        guard !active.exerciseIds.contains(exerciseId) else {
            throw WorkoutError.exerciseAlreadyInWorkout
        }
        let libraryExercise = try await loadExercise(id: exerciseId)
        let workoutExercise = WorkoutExercise(
            id: UUID(),
            workoutId: active.id,
            exerciseId: exerciseId,
            position: 0,
            targetSets: nil,
            targetReps: nil,
            restSeconds: libraryExercise.exercise.restSeconds
        )
        let previousSets = try await workoutRepository.previousSets(exerciseId: exerciseId)
        let sets = WorkoutSetPlanner.plannedSets(
            for: libraryExercise,
            workoutExerciseId: workoutExercise.id,
            targetSets: nil,
            targetReps: nil,
            previousSets: previousSets
        )
        try await workoutRepository.addExercise(workoutExercise, sets: sets)
    }

    private func loadExercise(id: UUID) async throws -> LibraryExercise {
        guard let exercise = try await exerciseRepository.exercise(id: id), !exercise.isArchived else {
            throw WorkoutError.exerciseUnavailable
        }
        switch exercise.load {
        case .bodyweight:
            return LibraryExercise(exercise: exercise, equipment: nil)
        case let .equipment(equipmentId):
            guard let equipment = try await equipmentRepository.equipment(id: equipmentId) else {
                throw WorkoutError.exerciseUnavailable
            }
            return LibraryExercise(exercise: exercise, equipment: equipment)
        }
    }
}
