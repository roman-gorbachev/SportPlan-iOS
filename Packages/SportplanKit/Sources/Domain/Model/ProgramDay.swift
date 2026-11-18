import Foundation

public struct ProgramDay: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let programId: UUID
    public var name: String
    public var label: String?
    public var position: Int

    public init(id: UUID, programId: UUID, name: String, label: String?, position: Int) {
        self.id = id
        self.programId = programId
        self.name = name
        self.label = label
        self.position = position
    }
}
