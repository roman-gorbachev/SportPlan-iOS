import Domain

struct AddExerciseUiData {
    let loadKind: ExerciseLoadKind
    let name: String
    let equipmentChoices: [AddExerciseEquipmentItem]
    let metric: ExerciseMetric
    let showsMetricPicker: Bool
    let restText: String
    let restAccessibilityText: String
    let canIncrementRest: Bool
    let canDecrementRest: Bool
    let description: String
    let dayContextTitle: String?
    let dayTargets: PlannedExerciseTargetsUiData?
    let canSave: Bool
    let isShowingSaveError: Bool
}
