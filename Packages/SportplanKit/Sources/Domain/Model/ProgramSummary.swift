import Foundation

public struct ProgramSummary: Identifiable, Hashable, Sendable {
    public let program: Program
    public let days: [ProgramDaySummary]

    public init(program: Program, days: [ProgramDaySummary]) {
        self.program = program
        self.days = days
    }

    public var id: Program.ID {
        return program.id
    }

    public var nextDay: ProgramDaySummary? {
        guard let firstDay = days.first else {
            return nil
        }
        let latest = days.enumerated()
            .compactMap { offset, summary -> (offset: Int, date: Date)? in
                guard let date = summary.lastWorkoutAt else {
                    return nil
                }
                return (offset: offset, date: date)
            }
            .max { lhs, rhs in
                return lhs.date < rhs.date
            }
        guard let latest else {
            return firstDay
        }
        return days[(latest.offset + 1) % days.count]
    }
}
