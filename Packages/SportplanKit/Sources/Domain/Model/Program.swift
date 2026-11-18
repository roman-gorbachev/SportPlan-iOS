import Foundation

public struct Program: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var position: Int
    public let createdAt: Date

    public init(id: UUID, name: String, position: Int, createdAt: Date) {
        self.id = id
        self.name = name
        self.position = position
        self.createdAt = createdAt
    }
}
