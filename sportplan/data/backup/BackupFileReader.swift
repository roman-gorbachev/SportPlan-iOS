import Domain
import Foundation

nonisolated enum BackupFileReader {
    static func read(fileURL: URL) throws -> Data {
        let isAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            throw BackupError.unreadable
        }
    }
}
