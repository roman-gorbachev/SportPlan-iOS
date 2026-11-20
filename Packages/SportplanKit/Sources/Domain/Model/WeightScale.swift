public struct WeightScale: Hashable, Sendable {
    private static let bodyweightStep = Weight(grams: 2_500)

    public let minimum: Weight
    public let step: Weight
    public let isAddedWeight: Bool

    public init(equipment: Equipment?) {
        if let equipment {
            minimum = equipment.kind.hasBaseWeight ? equipment.baseWeight : .zero
            step = equipment.weightStep
            isAddedWeight = false
        } else {
            minimum = .zero
            step = Self.bodyweightStep
            isAddedWeight = true
        }
    }
}
