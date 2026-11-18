import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

struct MigrationTests {
    private static let tables = [
        "equipment", "exercise", "program", "program_day", "planned_exercise",
        "workout", "workout_exercise", "set_entry", "plate",
    ]
    private static let seededPlates: [(grams: Int, colorHex: String)] = [
        (grams: 25_000, colorHex: "#D7261E"),
        (grams: 20_000, colorHex: "#1F5FBF"),
        (grams: 15_000, colorHex: "#F2C200"),
        (grams: 10_000, colorHex: "#1E8A4C"),
        (grams: 5_000, colorHex: "#FFFFFF"),
        (grams: 2_500, colorHex: "#D7261E"),
        (grams: 1_250, colorHex: "#A8A8A3"),
    ]

    @Test func createsAllTables() throws {
        let database = try DatabaseFixtures.makeDatabase()
        try database.reader.read { db in
            for table in Self.tables {
                let exists = try db.tableExists(table)
                #expect(exists, "missing table \(table)")
            }
        }
    }

    @Test func seedsStandardIWFPlates() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let rows = try database.reader.read { db in
            return try Row.fetchAll(db, sql: "SELECT weight_g, color_hex FROM plate ORDER BY weight_g DESC")
        }
        let plates = rows.map { row in
            return (grams: row["weight_g"] as Int, colorHex: row["color_hex"] as String)
        }
        #expect(plates.map(\.grams) == Self.seededPlates.map(\.grams))
        #expect(plates.map(\.colorHex) == Self.seededPlates.map(\.colorHex))
    }

    @Test func seededPlatesMapToDomain() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let plates = try database.reader.read { db in
            return try PlateRecord.fetchAll(db).map { record in
                return try record.toDomainModel()
            }
        }
        #expect(plates.count == Self.seededPlates.count)
    }

    @Test func storesIdentifiersAsLowercaseText() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let equipment = DatabaseFixtures.makeEquipment()
        let storedId = try database.writer.write { db in
            try EquipmentRecord(equipment).insert(db)
            return try String.fetchOne(db, sql: "SELECT id FROM equipment WHERE typeof(id) = 'text'")
        }
        #expect(storedId == equipment.id.uuidString.lowercased())
    }
}
