import Domain
import Foundation
import Testing

struct PlateLoadingTests {
    private static let plates = StandardPlates.makeIWFSet()

    private static func kilograms(_ loading: PlateLoading) -> [Double] {
        return loading.platesPerSide.map(\.weight.kilograms)
    }

    @Test func exactWeightIsLoadedGreedilyFromTheHeaviestPlate() {
        let loading = PlateLoading(weight: Weight(kilograms: 100), baseWeight: Weight(kilograms: 20), plates: Self.plates)
        #expect(Self.kilograms(loading) == [25, 15])
        #expect(loading.isExact)
    }

    @Test func smallestPlateIsOneAndAQuarter() {
        let loading = PlateLoading(weight: Weight(kilograms: 22.5), baseWeight: Weight(kilograms: 20), plates: Self.plates)
        #expect(Self.kilograms(loading) == [1.25])
        #expect(loading.isExact)
    }

    @Test func platesRepeatWithoutLimit() {
        let loading = PlateLoading(weight: Weight(kilograms: 140), baseWeight: Weight(kilograms: 20), plates: Self.plates)
        #expect(Self.kilograms(loading) == [25, 25, 10])
    }

    @Test func remainderIsReportedPerSide() {
        let loading = PlateLoading(weight: Weight(kilograms: 61), baseWeight: Weight(kilograms: 20), plates: Self.plates)
        #expect(Self.kilograms(loading) == [20])
        #expect(loading.remainderPerSide == Weight(kilograms: 0.5))
        #expect(!loading.isExact)
    }

    @Test func weightAtOrBelowTheBarLoadsNothing() {
        for kilograms in [20.0, 15.0] {
            let loading = PlateLoading(weight: Weight(kilograms: kilograms), baseWeight: Weight(kilograms: 20), plates: Self.plates)
            #expect(loading.platesPerSide.isEmpty)
            #expect(loading.remainderPerSide == .zero)
        }
    }

    @Test func onlyPlateLoadedEquipmentHasLoading() {
        let weight = Weight(kilograms: 60)
        #expect(PlateLoading(weight: weight, exercise: DomainFixtures.makeLibraryExercise(), plates: Self.plates) != nil)
        #expect(PlateLoading(weight: weight, exercise: DomainFixtures.makeLibraryExercise(kind: .plateLoadedMachine), plates: Self.plates) != nil)
        #expect(PlateLoading(weight: weight, exercise: DomainFixtures.makeLibraryExercise(kind: .dumbbell), plates: Self.plates) == nil)
        #expect(PlateLoading(weight: weight, exercise: DomainFixtures.makeLibraryExercise(kind: .selectorizedMachine), plates: Self.plates) == nil)
        #expect(PlateLoading(weight: weight, exercise: DomainFixtures.makeLibraryExercise(kind: nil), plates: Self.plates) == nil)
    }
}
