import Domain
import Testing

struct EstimatedOneRepMaxTests {
    @Test func singleRepIsTheWeightItself() {
        #expect(EstimatedOneRepMax.make(weight: Weight(kilograms: 100), reps: 1) == Weight(kilograms: 100))
    }

    @Test func usesTheEpleyFormulaUpToTwelveReps() {
        #expect(EstimatedOneRepMax.make(weight: Weight(kilograms: 65), reps: 8) == Weight(grams: 82_333))
        #expect(EstimatedOneRepMax.make(weight: Weight(kilograms: 60), reps: 12) == Weight(kilograms: 84))
    }

    @Test func skipsSetsOutsideTheRepRange() {
        #expect(EstimatedOneRepMax.make(weight: Weight(kilograms: 60), reps: 13) == nil)
        #expect(EstimatedOneRepMax.make(weight: Weight(kilograms: 60), reps: 0) == nil)
        #expect(EstimatedOneRepMax.make(weight: Weight(kilograms: 60), reps: nil) == nil)
    }
}
