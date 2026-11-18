import Foundation

public struct Equipment: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var kind: EquipmentKind
    public var baseWeight: Weight
    public var weightStep: Weight
    public var isArchived: Bool
    public let createdAt: Date

    public init(
        id: UUID,
        name: String,
        kind: EquipmentKind,
        baseWeight: Weight,
        weightStep: Weight,
        isArchived: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.baseWeight = baseWeight
        self.weightStep = weightStep
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
