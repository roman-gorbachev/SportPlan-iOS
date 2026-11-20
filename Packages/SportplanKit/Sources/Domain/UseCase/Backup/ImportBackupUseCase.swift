import Foundation

public struct ImportBackupUseCase: Sendable {
    private let backupRepository: any BackupRepository
    private let workoutRepository: any WorkoutRepository

    public init(backupRepository: any BackupRepository, workoutRepository: any WorkoutRepository) {
        self.backupRepository = backupRepository
        self.workoutRepository = workoutRepository
    }

    public func execute(candidate: BackupCandidate) async throws {
        guard try await workoutRepository.activeWorkout() == nil else {
            throw BackupError.workoutInProgress
        }
        try await backupRepository.replaceAll(contents: candidate.contents)
    }
}
