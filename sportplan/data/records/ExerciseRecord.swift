import Domain
import Foundation
import GRDB

nonisolated struct ExerciseRecord: AppRecord {
    static let databaseTableName = "exercise"

    var id: UUID
    var name: String
    var description: String?
    var equipmentId: UUID?
    var metric: String
    var restSec: Int
    var isArchived: Bool
    var createdAt: Date

    init(_ exercise: Exercise) {
        id = exercise.id
        name = exercise.name
        description = exercise.description
        switch exercise.load {
        case .bodyweight:
            equipmentId = nil
        case let .equipment(id):
            equipmentId = id
        }
        metric = exercise.metric.rawValue
        restSec = exercise.restSeconds
        isArchived = exercise.isArchived
        createdAt = exercise.createdAt
    }

    func toDomainModel() throws -> Exercise {
        guard let metric = ExerciseMetric(rawValue: metric) else {
            throw RecordMappingError.invalidValue(table: Self.databaseTableName, column: "metric")
        }
        let load: ExerciseLoad = equipmentId.map { id in
            return ExerciseLoad.equipment(id: id)
        } ?? .bodyweight
        return Exercise(
            id: id,
            name: name,
            description: description,
            load: load,
            metric: metric,
            restSeconds: restSec,
            isArchived: isArchived,
            createdAt: createdAt
        )
    }
}
