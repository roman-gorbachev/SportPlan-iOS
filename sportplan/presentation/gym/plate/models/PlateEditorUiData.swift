import DesignSystem
import Domain

struct PlateEditorUiData {
    var weightText: String
    var color: PlateColor
    var preview: PlateStackItem
    var previewAccessibilityText: String
    var hintText: String?
    let isExisting: Bool
    var canSave: Bool
    var isSaving: Bool
    var isShowingSaveError: Bool
}
