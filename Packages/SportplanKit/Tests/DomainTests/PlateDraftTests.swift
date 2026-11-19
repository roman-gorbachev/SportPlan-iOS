import Domain
import Testing

struct PlateDraftTests {
    private static let color = PlatePaletteColor.red.color

    @Test(arguments: [Plate.minimumWeight, Plate.maximumWeight])
    func acceptsBounds(weight: Weight) {
        let draft = PlateDraft(weight: weight, color: Self.color)
        #expect(draft.validationIssues(takenWeights: []).isEmpty)
    }

    @Test(arguments: [Plate.minimumWeight - Weight(grams: 1), Plate.maximumWeight + Weight(grams: 1)])
    func rejectsOutOfBounds(weight: Weight) {
        let draft = PlateDraft(weight: weight, color: Self.color)
        #expect(draft.validationIssues(takenWeights: []) == [.weightOutOfRange])
    }

    @Test func rejectsTakenWeight() {
        let draft = PlateDraft(weight: Weight(kilograms: 20), color: Self.color)
        #expect(draft.validationIssues(takenWeights: [Weight(kilograms: 20)]) == [.duplicateWeight])
    }
}
