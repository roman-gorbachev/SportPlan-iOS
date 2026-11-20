import Foundation

public protocol BackupRepository: Sendable {
    func makeBackup(exportedAt: Date) async throws -> Data
    func readBackup(fileURL: URL) async throws -> BackupCandidate
    func replaceAll(contents: Data) async throws
}
