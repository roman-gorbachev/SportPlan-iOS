import Domain

struct ExerciseEditorUiData {
    let title: String
    let name: String
    let description: String
    let equipmentHeader: String?
    let equipmentChoices: [AddExerciseEquipmentItem]
    let equipmentLockHint: String?
    let showsMetric: Bool
    let metric: ExerciseMetric
    let isMetricLocked: Bool
    let restText: String
    let restAccessibilityText: String
    let canIncrementRest: Bool
    let canDecrementRest: Bool
    let canSave: Bool
    let pendingArchive: LibraryArchiveConfirmation?
    let isShowingSaveError: Bool
    let isShowingArchiveError: Bool
}
