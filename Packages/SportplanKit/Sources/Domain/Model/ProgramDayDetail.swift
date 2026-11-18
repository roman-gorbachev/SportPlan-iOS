import Foundation

public struct ProgramDayDetail: Hashable, Sendable {
    public let day: ProgramDay
    public let programName: String
    public let exercises: [PlannedExerciseItem]

    public init(day: ProgramDay, programName: String, exercises: [PlannedExerciseItem]) {
        self.day = day
        self.programName = programName
        self.exercises = exercises
    }

    public var exerciseIds: Set<UUID> {
        return Set(exercises.map { item in
            return item.exercise.id
        })
    }
}
