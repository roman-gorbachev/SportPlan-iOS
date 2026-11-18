import Foundation

public struct ProgramDaySnapshot: Hashable, Sendable {
    public let programDayId: UUID?
    public let name: String
    public let label: String?

    public init(programDayId: UUID?, name: String, label: String?) {
        self.programDayId = programDayId
        self.name = name
        self.label = label
    }
}
