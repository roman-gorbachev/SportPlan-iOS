import Domain
import Testing

struct EquipmentDraftTests {
    private static func makeDraft(kind: EquipmentKind = .barbell) -> EquipmentDraft {
        return EquipmentDraft(
            name: "Олимпийский гриф",
            kind: kind,
            baseWeight: Weight(kilograms: 20),
            weightStep: Weight(kilograms: 2.5)
        )
    }

    @Test func acceptsRegularBarbell() {
        #expect(Self.makeDraft().isValid)
    }

    @Test func rejectsBlankName() {
        var draft = Self.makeDraft()
        draft.name = "   "
        #expect(draft.validationIssues == [.emptyName])
    }

    @Test func rejectsStepOutsideBounds() {
        var draft = Self.makeDraft()
        draft.weightStep = Weight(grams: 100)
        #expect(draft.validationIssues == [.weightStepOutOfRange])
        draft.weightStep = Weight(kilograms: 60)
        #expect(draft.validationIssues == [.weightStepOutOfRange])
    }

    @Test func rejectsBaseWeightAboveBound() {
        var draft = Self.makeDraft()
        draft.baseWeight = Weight(kilograms: 600)
        #expect(draft.validationIssues == [.baseWeightOutOfRange])
    }

    @Test func ignoresBaseWeightForKindsWithoutIt() {
        var draft = Self.makeDraft(kind: .selectorizedMachine)
        draft.baseWeight = Weight(kilograms: 600)
        #expect(draft.isValid)
        #expect(draft.effectiveBaseWeight == .zero)
    }
}
