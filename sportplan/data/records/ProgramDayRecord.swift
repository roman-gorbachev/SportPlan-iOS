import Domain
import Foundation
import GRDB

nonisolated struct ProgramDayRecord: AppRecord {
    static let databaseTableName = "program_day"

    var id: UUID
    var programId: UUID
    var name: String
    var label: String?
    var position: Int

    init(_ day: ProgramDay) {
        id = day.id
        programId = day.programId
        name = day.name
        label = day.label
        position = day.position
    }

    func toDomainModel() -> ProgramDay {
        return ProgramDay(id: id, programId: programId, name: name, label: label, position: position)
    }
}
