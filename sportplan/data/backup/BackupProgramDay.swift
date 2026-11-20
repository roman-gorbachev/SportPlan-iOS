import Foundation
import GRDB

nonisolated struct BackupProgramDay: AppRecord, Sendable {
    static let databaseTableName = "program_day"

    var id: UUID
    var programId: UUID
    var name: String
    var label: String?
    var position: Int
}
