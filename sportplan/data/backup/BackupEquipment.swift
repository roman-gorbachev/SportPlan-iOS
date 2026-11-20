import Foundation
import GRDB

nonisolated struct BackupEquipment: AppRecord, Sendable {
    static let databaseTableName = "equipment"

    var id: UUID
    var name: String
    var kind: String
    var baseWeightG: Int
    var weightStepG: Int
    var isArchived: Bool
    var createdAt: Date
}
