import Foundation
import GRDB

nonisolated struct BackupProgram: AppRecord, Sendable {
    static let databaseTableName = "program"

    var id: UUID
    var name: String
    var position: Int
    var createdAt: Date
}
