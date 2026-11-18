import Foundation

public struct Exercise: Identifiable, Hashable, Sendable {
    public static let defaultRestSeconds = 90
    public static let minimumRestSeconds = 0
    public static let maximumRestSeconds = 600
    public static let restStepSeconds = 15

    public let id: UUID
    public var name: String
    public var description: String?
    public var load: ExerciseLoad
    public var metric: ExerciseMetric
    public var restSeconds: Int
    public var isArchived: Bool
    public let createdAt: Date

    public init(
        id: UUID,
        name: String,
        description: String?,
        load: ExerciseLoad,
        metric: ExerciseMetric,
        restSeconds: Int,
        isArchived: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.load = load
        self.metric = metric
        self.restSeconds = restSeconds
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
