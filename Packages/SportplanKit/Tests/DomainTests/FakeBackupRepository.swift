import Domain
import Foundation
import Synchronization

final class FakeBackupRepository: BackupRepository {
    private struct State {
        var exportDates: [Date] = []
        var replacedContents: [Data] = []
    }

    private let state = Mutex(State())
    private let backup: Data
    private let readResult: Result<BackupCandidate, BackupError>

    init(backup: Data = Data(), readResult: Result<BackupCandidate, BackupError> = .failure(.unreadable)) {
        self.backup = backup
        self.readResult = readResult
    }

    var exportDates: [Date] {
        return state.withLock { state in
            return state.exportDates
        }
    }

    var replacedContents: [Data] {
        return state.withLock { state in
            return state.replacedContents
        }
    }

    func makeBackup(exportedAt: Date) async throws -> Data {
        state.withLock { state in
            state.exportDates.append(exportedAt)
        }
        return backup
    }

    func readBackup(fileURL: URL) async throws -> BackupCandidate {
        return try readResult.get()
    }

    func replaceAll(contents: Data) async throws {
        state.withLock { state in
            state.replacedContents.append(contents)
        }
    }
}
