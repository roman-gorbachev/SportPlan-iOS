import Foundation

public struct HeatmapDay: Identifiable, Hashable, Sendable {
    public let date: Date
    public let workingSetCount: Int
    public let isToday: Bool
    public let isFuture: Bool
    public let workoutIds: [UUID]

    public init(date: Date, workingSetCount: Int, isToday: Bool, isFuture: Bool, workoutIds: [UUID]) {
        self.date = date
        self.workingSetCount = workingSetCount
        self.isToday = isToday
        self.isFuture = isFuture
        self.workoutIds = workoutIds
    }

    public var id: Date {
        return date
    }

    public var level: HeatmapLevel {
        return HeatmapLevel(workingSetCount: workingSetCount)
    }
}
