import Foundation

struct SetEditorUiData: Identifiable {
    let id: UUID
    let title: String
    let exerciseName: String
    let weight: SetEditorWeightField
    let reps: String
    let canDecrementReps: Bool
    let canCopyLastWorkout: Bool
    let saveTitle: String
}
