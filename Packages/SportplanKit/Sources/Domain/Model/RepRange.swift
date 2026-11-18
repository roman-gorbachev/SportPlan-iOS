public struct RepRange: Hashable, Sendable {
    private static let minimumReps = 1

    public let min: Int
    public let max: Int

    public init?(min: Int, max: Int) {
        guard min >= Self.minimumReps, min <= max else {
            return nil
        }
        self.min = min
        self.max = max
    }
}
