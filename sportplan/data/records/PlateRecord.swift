import Domain
import Foundation
import GRDB

nonisolated struct PlateRecord: AppRecord {
    static let databaseTableName = "plate"

    var id: UUID
    var weightG: Int
    var colorHex: String

    init(_ plate: Plate) {
        id = plate.id
        weightG = plate.weight.grams
        colorHex = plate.color.hexString
    }

    func toDomainModel() throws -> Plate {
        guard let color = PlateColor(hexString: colorHex) else {
            throw RecordMappingError.invalidValue(table: Self.databaseTableName, column: "color_hex")
        }
        return Plate(id: id, weight: Weight(grams: weightG), color: color)
    }
}
