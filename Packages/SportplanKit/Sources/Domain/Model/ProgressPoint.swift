import Foundation

public struct ProgressPoint: Identifiable, Hashable, Sendable {
    public let workoutId: UUID
    public let date: Date
    public let value: Int
    public let isRecord: Bool

    public init(workoutId: UUID, date: Date, value: Int, isRecord: Bool) {
        self.workoutId = workoutId
        self.date = date
        self.value = value
        self.isRecord = isRecord
    }

    public var id: UUID {
        return workoutId
    }
}
