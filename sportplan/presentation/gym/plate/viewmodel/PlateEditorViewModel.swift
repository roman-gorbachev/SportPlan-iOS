import DesignSystem
import Domain
import Foundation
import Observation

@Observable
final class PlateEditorViewModel {
    private static let defaultColor = PlatePaletteColor.red
    private static let placeholderPreview = PlateStackItem(rgb: defaultColor.color.rgb, kilograms: .zero)

    @ObservationIgnored private let target: PlateEditorTarget
    @ObservationIgnored private let loadPlateEditor: LoadPlateEditorUseCase
    @ObservationIgnored private let savePlate: SavePlateUseCase
    @ObservationIgnored private let deletePlate: DeletePlateUseCase
    @ObservationIgnored private var existingId: UUID?
    @ObservationIgnored private var takenWeights: Set<Weight> = []

    private(set) var editorUiState: PlateEditorUiState = .loading

    init(
        target: PlateEditorTarget,
        loadPlateEditor: LoadPlateEditorUseCase,
        savePlate: SavePlateUseCase,
        deletePlate: DeletePlateUseCase
    ) {
        self.target = target
        self.loadPlateEditor = loadPlateEditor
        self.savePlate = savePlate
        self.deletePlate = deletePlate
    }

    func load() async {
        var id: UUID?
        if case let .existing(existingId) = target {
            id = existingId
        }
        do {
            let snapshot = try await loadPlateEditor.execute(id: id)
            existingId = snapshot.plate?.id
            takenWeights = snapshot.takenWeights
            editorUiState = .success(data: recalculated(PlateEditorUiData(
                weightText: snapshot.plate.map { plate in
                    return WeightFormatting.kilograms(plate.weight)
                } ?? "",
                color: snapshot.plate?.color ?? Self.defaultColor.color,
                preview: Self.placeholderPreview,
                previewAccessibilityText: "",
                hintText: nil,
                isExisting: snapshot.plate != nil,
                canSave: false,
                isSaving: false,
                isShowingSaveError: false
            )))
        } catch {
            editorUiState = .error(error: error)
        }
    }

    func updateWeight(_ text: String) {
        updateData { data in
            data.weightText = text
        }
    }

    func selectColor(_ color: PlateColor) {
        updateData { data in
            data.color = color
        }
    }

    func dismissSaveError() {
        updateData { data in
            data.isShowingSaveError = false
        }
    }

    func save() async -> Bool {
        guard case let .success(data) = editorUiState, data.canSave, let weight = WeightFormatting.parseKilograms(data.weightText) else {
            return false
        }
        updateData { data in
            data.isSaving = true
        }
        do {
            _ = try await savePlate.execute(draft: PlateDraft(weight: weight, color: data.color), existingId: existingId)
            return true
        } catch {
            updateData { data in
                data.isSaving = false
                data.isShowingSaveError = true
            }
            return false
        }
    }

    func delete() async -> Bool {
        guard let existingId else {
            return false
        }
        do {
            try await deletePlate.execute(id: existingId)
            return true
        } catch {
            updateData { data in
                data.isShowingSaveError = true
            }
            return false
        }
    }

    private func updateData(_ change: (inout PlateEditorUiData) -> Void) {
        guard case var .success(data) = editorUiState else {
            return
        }
        change(&data)
        editorUiState = .success(data: recalculated(data))
    }

    private func recalculated(_ data: PlateEditorUiData) -> PlateEditorUiData {
        var result = data
        let weight = WeightFormatting.parseKilograms(data.weightText)
        let issues = weight.map { weight in
            return PlateDraft(weight: weight, color: data.color).validationIssues(takenWeights: takenWeights)
        }
        result.preview = PlateStackItem(rgb: data.color.rgb, kilograms: weight?.kilograms ?? 0)
        result.previewAccessibilityText = Self.previewAccessibilityText(weight: weight, color: data.color)
        result.hintText = Self.hintText(weight: weight, issues: issues ?? [])
        result.canSave = !data.isSaving && issues?.isEmpty == true
        return result
    }

    private static func hintText(weight: Weight?, issues: Set<PlateValidationIssue>) -> String? {
        guard let weight else {
            return nil
        }
        if issues.contains(.weightOutOfRange) {
            return String(localized: "plate.editor.outOfRange \(WeightFormatting.kilograms(Plate.minimumWeight)) \(WeightFormatting.kilograms(Plate.maximumWeight))")
        }
        if issues.contains(.duplicateWeight) {
            return String(localized: "plate.editor.duplicate \(WeightFormatting.kilograms(weight))")
        }
        return nil
    }

    private static func previewAccessibilityText(weight: Weight?, color: PlateColor) -> String {
        let colorName = PlateFormatting.colorName(color).localizedLowercase
        guard let weight else {
            return String(localized: "plate.editor.previewNoWeight \(colorName)")
        }
        return String(localized: "plate.editor.preview \(PlateFormatting.weightText(weight)) \(colorName)")
    }
}
