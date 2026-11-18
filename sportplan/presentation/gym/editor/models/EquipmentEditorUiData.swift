import Domain

struct EquipmentEditorUiData {
    var name: String
    var kind: EquipmentKind
    var baseWeightText: String
    var weightStepText: String
    let isExisting: Bool
    let isKindLocked: Bool
    let exerciseCount: Int
    var canSave: Bool
    var isSaving: Bool
    var isShowingSaveError: Bool
}
