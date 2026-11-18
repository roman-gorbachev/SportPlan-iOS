public struct ProgramDaySummary: Identifiable, Hashable, Sendable {
    public let day: ProgramDay
    public let exerciseCount: Int

    public init(day: ProgramDay, exerciseCount: Int) {
        self.day = day
        self.exerciseCount = exerciseCount
    }

    public var id: ProgramDay.ID {
        return day.id
    }
}
