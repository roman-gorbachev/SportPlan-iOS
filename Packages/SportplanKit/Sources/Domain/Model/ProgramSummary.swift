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
}
