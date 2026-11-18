import Foundation
import GRDB

nonisolated extension AppDatabase {
    private static let directoryName = "Database"
    private static let fileName = "sportplan.sqlite"

    static func makePersistent() throws -> AppDatabase {
        let fileManager = FileManager.default
        let directory = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: directoryName, directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appending(path: fileName).path(percentEncoded: false)
        return try AppDatabase(DatabasePool(path: path))
    }
}
