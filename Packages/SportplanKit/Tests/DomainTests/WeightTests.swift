import Testing
@testable import Domain

struct WeightTests {
    @Test func convertsKilogramsToGrams() {
        #expect(Weight(kilograms: 62.5).grams == 62_500)
        #expect(Weight(kilograms: 1.25).grams == 1_250)
        #expect(Weight(kilograms: 0.25).grams == 250)
    }

    @Test func roundsKilogramsToNearestGram() {
        #expect(Weight(kilograms: 2.2046).grams == 2_205)
        #expect(Weight(kilograms: 0.0004).grams == 0)
    }

    @Test func convertsGramsToKilograms() {
        #expect(Weight(grams: 102_500).kilograms == 102.5)
    }

    @Test func addsAndSubtracts() {
        let bar = Weight(kilograms: 20)
        let plates = Weight(kilograms: 42.5)
        #expect(bar + plates == Weight(kilograms: 62.5))
        #expect(Weight(kilograms: 62.5) - bar == plates)
    }

    @Test func multipliesByCount() {
        #expect(Weight(kilograms: 1.25) * 2 == Weight(kilograms: 2.5))
    }

    @Test func comparesByGrams() {
        #expect(Weight(kilograms: 60) < Weight(kilograms: 62.5))
        #expect(Weight.zero < Weight(grams: 1))
    }
}
