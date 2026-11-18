import Domain
import Foundation
import Testing

struct ExerciseDraftTests {
    @Test func requiresNameAndEquipmentForEquipmentKinds() {
        let draft = ExerciseDraft(name: "   ", loadKind: .equipment(.barbell))
        #expect(draft.validationIssues == [.emptyName, .missingEquipment])
    }

    @Test func bodyweightNeedsNoEquipment() {
        let draft = ExerciseDraft(name: "Подтягивания", loadKind: .bodyweight)
        #expect(draft.isValid)
        #expect(draft.load == .bodyweight)
    }

    @Test func durationIsOnlyForBodyweight() {
        let barbell = ExerciseDraft(name: "Удержание", loadKind: .equipment(.barbell), equipmentId: UUID(), metric: .duration)
        #expect(barbell.validationIssues == [.durationNotAllowed])
        let plank = ExerciseDraft(name: "Планка", loadKind: .bodyweight, metric: .duration)
        #expect(plank.isValid)
    }

    @Test func changingLoadKindResetsEquipmentAndMetric() {
        var draft = ExerciseDraft(name: "Планка", loadKind: .bodyweight, metric: .duration)
        draft.loadKind = .equipment(.dumbbell)
        #expect(draft.metric == .weightReps)
        draft.equipmentId = UUID()
        draft.loadKind = .equipment(.barbell)
        #expect(draft.equipmentId == nil)
    }

    @Test func restStepsStayWithinBounds() {
        var draft = ExerciseDraft(loadKind: .bodyweight, restSeconds: 15)
        draft.decrementRest()
        #expect(draft.restSeconds == 0)
        #expect(!draft.canDecrementRest)
        draft.decrementRest()
        #expect(draft.restSeconds == 0)
        draft.restSeconds = 585
        draft.incrementRest()
        #expect(draft.restSeconds == 600)
        #expect(!draft.canIncrementRest)
        draft.restSeconds = 601
        #expect(draft.validationIssues.contains(.restOutOfRange))
    }

    @Test func trimsDescriptionToNil() {
        let draft = ExerciseDraft(loadKind: .bodyweight, description: "  \n ")
        #expect(draft.trimmedDescription == nil)
    }

    @Test func quickExerciseFillsKindAndMetric() {
        let draft = ExerciseDraft(quickExercise: .plank, name: "Планка")
        #expect(draft.loadKind == .bodyweight)
        #expect(draft.metric == .duration)
        #expect(draft.restSeconds == Exercise.defaultRestSeconds)
    }

    @Test func quickExercisesMatchTheBrief() {
        #expect(QuickExercise.allCases.count == 7)
        let timed = QuickExercise.allCases.filter { quick in
            return quick.metric == .duration
        }
        #expect(timed == [.plank])
        for quick in QuickExercise.allCases {
            #expect(quick.metric != .duration || quick.loadKind.allowsDuration)
        }
    }
}
