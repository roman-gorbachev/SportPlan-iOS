import Domain
import Foundation
import Testing

struct SetEntryDraftTests {
    @Test func barbellWeightStepsByEquipmentStepAndStopsAtTheBar() {
        let bench = DomainFixtures.makeLibraryExercise()
        var draft = SetEntryDraft(weight: Weight(kilograms: 22.5), reps: 8, durationSeconds: nil)
        draft.incrementWeight(for: bench)
        #expect(draft.weight == Weight(kilograms: 25))
        draft.decrementWeight(for: bench)
        draft.decrementWeight(for: bench)
        #expect(draft.weight == Weight(kilograms: 20))
        #expect(!draft.canDecrementWeight(for: bench))
        draft.decrementWeight(for: bench)
        #expect(draft.weight == Weight(kilograms: 20))
    }

    @Test func offGridWeightDecrementsToTheBar() {
        let bench = DomainFixtures.makeLibraryExercise()
        var draft = SetEntryDraft(weight: Weight(kilograms: 21), reps: 8, durationSeconds: nil)
        #expect(draft.canDecrementWeight(for: bench))
        draft.decrementWeight(for: bench)
        #expect(draft.weight == Weight(kilograms: 20))
    }

    @Test func bodyweightLoadStepsByTwoAndAHalfKilogramsFromZero() {
        let dips = DomainFixtures.makeLibraryExercise(name: "Брусья", kind: nil)
        var draft = SetEntryDraft(weight: .zero, reps: 10, durationSeconds: nil)
        #expect(!draft.canDecrementWeight(for: dips))
        draft.incrementWeight(for: dips)
        #expect(draft.weight == Weight(kilograms: 2.5))
        draft.decrementWeight(for: dips)
        #expect(draft.weight == .zero)
    }

    @Test func repsStepByOneAndStopAtZero() {
        var draft = SetEntryDraft(weight: .zero, reps: 1, durationSeconds: nil)
        draft.incrementReps()
        #expect(draft.reps == 2)
        draft.decrementReps()
        draft.decrementReps()
        #expect(draft.reps == 0)
        #expect(!draft.canDecrementReps)
        draft.decrementReps()
        #expect(draft.reps == 0)
    }

    @Test func validationFollowsTheMetric() {
        #expect(SetEntryDraft(weight: .zero, reps: 0, durationSeconds: nil).isValid(for: .weightReps))
        #expect(!SetEntryDraft(weight: .zero, reps: nil, durationSeconds: nil).isValid(for: .weightReps))
        #expect(!SetEntryDraft(weight: .zero, reps: -1, durationSeconds: nil).isValid(for: .weightReps))
        #expect(!SetEntryDraft(weight: Weight(grams: -1), reps: 5, durationSeconds: nil).isValid(for: .weightReps))
        #expect(SetEntryDraft(weight: .zero, reps: nil, durationSeconds: 60).isValid(for: .duration))
        #expect(SetEntryDraft(weight: .zero, reps: nil, durationSeconds: nil).isValid(for: .duration))
        #expect(!SetEntryDraft(weight: .zero, reps: 5, durationSeconds: 60).isValid(for: .duration))
    }
}
