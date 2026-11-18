import Foundation

public struct Plate: Identifiable, Hashable, Sendable {
    public static let minimumWeight = Weight(grams: 250)
    public static let maximumWeight = Weight(grams: 50_000)

    public let id: UUID
    public var weight: Weight
    public var color: PlateColor

    public init(id: UUID, weight: Weight, color: PlateColor) {
        self.id = id
        self.weight = weight
        self.color = color
    }
}
