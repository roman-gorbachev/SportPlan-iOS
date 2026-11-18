import Foundation

public struct Workout: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let programDay: ProgramDaySnapshot?
    public let startedAt: Date
    public var finishedAt: Date?
    public var note: String?
    public var rest: RestPeriod?

    public init(
        id: UUID,
        programDay: ProgramDaySnapshot?,
        startedAt: Date,
        finishedAt: Date?,
        note: String?,
        rest: RestPeriod?
    ) {
        self.id = id
        self.programDay = programDay
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.note = note
        self.rest = rest
    }
}
