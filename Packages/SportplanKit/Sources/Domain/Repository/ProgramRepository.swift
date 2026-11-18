import Foundation

public protocol ProgramRepository: Sendable {
    func observePrograms() -> AsyncThrowingStream<[ProgramSummary], any Error>
    func observeDay(id: UUID) -> AsyncThrowingStream<ProgramDayDetail?, any Error>
    func createProgram(_ program: Program, firstDay: ProgramDay) async throws -> Program
    func renameProgram(id: UUID, name: String) async throws
    func deleteProgram(id: UUID) async throws
    func addDay(_ day: ProgramDay) async throws -> ProgramDay
    func updateDay(id: UUID, name: String, label: String?) async throws
    func deleteDay(id: UUID) async throws
    func plannedExercise(id: UUID) async throws -> PlannedExercise?
    func addPlannedExercise(_ plannedExercise: PlannedExercise) async throws -> PlannedExercise
    func updateTargets(plannedExerciseId: UUID, targets: PlannedExerciseTargets) async throws
    func removePlannedExercise(id: UUID) async throws
    func reorderPlannedExercises(dayId: UUID, orderedIds: [UUID]) async throws
}
