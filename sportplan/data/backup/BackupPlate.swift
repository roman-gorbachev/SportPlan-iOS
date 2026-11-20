import Foundation
import GRDB

nonisolated struct BackupPlate: AppRecord, Sendable {
    static let databaseTableName = "plate"

    var id: UUID
    var weightG: Int
    var colorHex: String
}
