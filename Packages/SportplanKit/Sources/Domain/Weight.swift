public struct Weight: Hashable, Comparable, Sendable {
    private static let gramsPerKilogram = 1000

    public static let zero = Weight(grams: 0)

    public let grams: Int

    public init(grams: Int) {
        self.grams = grams
    }

    public init(kilograms: Double) {
        self.grams = Int((kilograms * Double(Self.gramsPerKilogram)).rounded())
    }

    public var kilograms: Double {
        return Double(grams) / Double(Self.gramsPerKilogram)
    }

    public static func < (lhs: Weight, rhs: Weight) -> Bool {
        return lhs.grams < rhs.grams
    }

    public static func + (lhs: Weight, rhs: Weight) -> Weight {
        return Weight(grams: lhs.grams + rhs.grams)
    }

    public static func - (lhs: Weight, rhs: Weight) -> Weight {
        return Weight(grams: lhs.grams - rhs.grams)
    }

    public static func * (lhs: Weight, rhs: Int) -> Weight {
        return Weight(grams: lhs.grams * rhs)
    }
}
