import Foundation

public struct ReadBackupUseCase: Sendable {
    private let repository: any BackupRepository

    public init(repository: any BackupRepository) {
        self.repository = repository
    }

    public func execute(fileURL: URL) async throws -> BackupCandidate {
        return try await repository.readBackup(fileURL: fileURL)
    }
}
