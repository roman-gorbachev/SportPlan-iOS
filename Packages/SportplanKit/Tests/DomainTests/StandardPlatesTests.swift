import Domain
import Testing

struct StandardPlatesTests {
    private static let iwfPlateCount = 7

    @Test func containsSevenPlates() {
        #expect(StandardPlates.makeIWFSet().count == Self.iwfPlateCount)
    }

    @Test func weightsAreUnique() {
        let weights = StandardPlates.makeIWFSet().map(\.weight)
        #expect(Set(weights).count == weights.count)
    }

    @Test func weightsAreWithinBounds() {
        let plates = StandardPlates.makeIWFSet()
        #expect(plates.allSatisfy { plate in
            return plate.weight >= Plate.minimumWeight && plate.weight <= Plate.maximumWeight
        })
    }

    @Test func eachSetGetsFreshIdentifiers() {
        let first = Set(StandardPlates.makeIWFSet().map(\.id))
        let second = Set(StandardPlates.makeIWFSet().map(\.id))
        #expect(first.isDisjoint(with: second))
    }
}
