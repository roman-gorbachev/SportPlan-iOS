import Domain
import Foundation
import GRDB

nonisolated struct EquipmentRecord: AppRecord {
    static let databaseTableName = "equipment"

    var id: UUID
    var name: String
    var kind: String
    var baseWeightG: Int
    var weightStepG: Int
    var isArchived: Bool
    var createdAt: Date

    init(_ equipment: Equipment) {
        id = equipment.id
        name = equipment.name
        kind = equipment.kind.rawValue
        baseWeightG = equipment.baseWeight.grams
        weightStepG = equipment.weightStep.grams
        isArchived = equipment.isArchived
        createdAt = equipment.createdAt
    }

    func toDomainModel() throws -> Equipment {
        guard let kind = EquipmentKind(rawValue: kind) else {
            throw RecordMappingError.invalidValue(table: Self.databaseTableName, column: "kind")
        }
        return Equipment(
            id: id,
            name: name,
            kind: kind,
            baseWeight: Weight(grams: baseWeightG),
            weightStep: Weight(grams: weightStepG),
            isArchived: isArchived,
            createdAt: createdAt
        )
    }
}
