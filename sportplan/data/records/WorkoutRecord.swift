import Domain
import Foundation
import GRDB

nonisolated struct WorkoutRecord: AppRecord {
    static let databaseTableName = "workout"

    var id: UUID
    var programDayId: UUID?
    var programDayName: String?
    var programDayLabel: String?
    var startedAt: Date
    var finishedAt: Date?
    var note: String?
    var restStartedAt: Date?
    var restEndsAt: Date?

    init(_ workout: Workout) {
        id = workout.id
        programDayId = workout.programDay?.programDayId
        programDayName = workout.programDay?.name
        programDayLabel = workout.programDay?.label
        startedAt = workout.startedAt
        finishedAt = workout.finishedAt
        note = workout.note
        restStartedAt = workout.rest?.startedAt
        restEndsAt = workout.rest?.endsAt
    }

    func toDomainModel() throws -> Workout {
        return Workout(
            id: id,
            programDay: programDayName.map { name in
                return ProgramDaySnapshot(programDayId: programDayId, name: name, label: programDayLabel)
            },
            startedAt: startedAt,
            finishedAt: finishedAt,
            note: note,
            rest: try restPeriod()
        )
    }

    private func restPeriod() throws -> RestPeriod? {
        switch (restStartedAt, restEndsAt) {
        case (nil, nil):
            return nil
        case let (startedAt?, endsAt?):
            return RestPeriod(startedAt: startedAt, endsAt: endsAt)
        default:
            throw RecordMappingError.invalidValue(table: Self.databaseTableName, column: "rest_started_at")
        }
    }
}
