import Foundation

public struct ProgramDaySummary: Identifiable, Hashable, Sendable {
    public let day: ProgramDay
    public let exerciseNames: [String]
    public let lastWorkoutAt: Date?

    public init(day: ProgramDay, exerciseNames: [String], lastWorkoutAt: Date?) {
        self.day = day
        self.exerciseNames = exerciseNames
        self.lastWorkoutAt = lastWorkoutAt
    }

    public var id: ProgramDay.ID {
        return day.id
    }

    public var exerciseCount: Int {
        return exerciseNames.count
    }
}
