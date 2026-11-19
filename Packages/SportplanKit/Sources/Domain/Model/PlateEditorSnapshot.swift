public struct PlateEditorSnapshot: Hashable, Sendable {
    public let plate: Plate?
    public let takenWeights: Set<Weight>

    public init(plate: Plate?, takenWeights: Set<Weight>) {
        self.plate = plate
        self.takenWeights = takenWeights
    }
}
