import Domain
import Foundation
import GRDB

nonisolated struct ProgramRecord: AppRecord {
    static let databaseTableName = "program"

    var id: UUID
    var name: String
    var position: Int
    var createdAt: Date

    init(_ program: Program) {
        id = program.id
        name = program.name
        position = program.position
        createdAt = program.createdAt
    }

    func toDomainModel() -> Program {
        return Program(id: id, name: name, position: position, createdAt: createdAt)
    }
}
