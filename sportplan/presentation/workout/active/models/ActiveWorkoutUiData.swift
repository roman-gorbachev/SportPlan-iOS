import Foundation

struct ActiveWorkoutUiData {
    let title: String
    let subtitle: String?
    let startedAt: Date
    let exercises: [ActiveExerciseItem]
    let note: String
    let editor: SetEditorUiData?
    let confirmation: ActiveWorkoutConfirmation?
    let isShowingError: Bool
}
