import Domain
import Testing

struct RepRangeTests {
    @Test func acceptsRange() {
        let range = RepRange(min: 8, max: 12)
        #expect(range?.min == 8)
        #expect(range?.max == 12)
    }

    @Test func acceptsSingleNumber() {
        #expect(RepRange(min: 5, max: 5) != nil)
    }

    @Test func rejectsMinAboveMax() {
        #expect(RepRange(min: 12, max: 8) == nil)
    }

    @Test func rejectsZeroReps() {
        #expect(RepRange(min: 0, max: 5) == nil)
    }
}
