import Domain
import Foundation
import Observation

@Observable
final class EquipmentEditorViewModel {
    private static let defaultBarbellWeight = Weight(grams: 20_000)
    private static let defaultWeightStep = Weight(grams: 2_500)

    @ObservationIgnored private let target: EquipmentEditorTarget
    @ObservationIgnored private let loadEquipmentEditor: LoadEquipmentEditorUseCase
    @ObservationIgnored private let saveEquipment: SaveEquipmentUseCase
    @ObservationIgnored private let archiveEquipment: ArchiveEquipmentUseCase
    @ObservationIgnored private var existingId: UUID?

    private(set) var editorUiState: EquipmentEditorUiState = .loading

    init(
        target: EquipmentEditorTarget,
        loadEquipmentEditor: LoadEquipmentEditorUseCase,
        saveEquipment: SaveEquipmentUseCase,
        archiveEquipment: ArchiveEquipmentUseCase
    ) {
        self.target = target
        self.loadEquipmentEditor = loadEquipmentEditor
        self.saveEquipment = saveEquipment
        self.archiveEquipment = archiveEquipment
    }

    func load() async {
        switch target {
        case let .new(kind):
            let baseWeight = kind == .barbell ? Self.defaultBarbellWeight : nil
            editorUiState = .success(data: Self.recalculated(EquipmentEditorUiData(
                name: "",
                kind: kind,
                baseWeightText: baseWeight.map(WeightFormatting.kilograms) ?? "",
                weightStepText: WeightFormatting.kilograms(Self.defaultWeightStep),
                isExisting: false,
                isKindLocked: false,
                exerciseCount: 0,
                canSave: false,
                isSaving: false,
                isShowingSaveError: false
            )))
        case let .existing(id):
            do {
                let snapshot = try await loadEquipmentEditor.execute(id: id)
                existingId = id
                let equipment = snapshot.equipment
                editorUiState = .success(data: Self.recalculated(EquipmentEditorUiData(
                    name: equipment.name,
                    kind: equipment.kind,
                    baseWeightText: equipment.kind.hasBaseWeight ? WeightFormatting.kilograms(equipment.baseWeight) : "",
                    weightStepText: WeightFormatting.kilograms(equipment.weightStep),
                    isExisting: true,
                    isKindLocked: snapshot.isKindLocked,
                    exerciseCount: snapshot.exerciseCount,
                    canSave: false,
                    isSaving: false,
                    isShowingSaveError: false
                )))
            } catch {
                editorUiState = .error(error: error)
            }
        }
    }

    func updateName(_ name: String) {
        updateData { data in
            data.name = name
        }
    }

    func updateKind(_ kind: EquipmentKind) {
        updateData { data in
            guard !data.isKindLocked else {
                return
            }
            data.kind = kind
        }
    }

    func updateBaseWeight(_ text: String) {
        updateData { data in
            data.baseWeightText = text
        }
    }

    func updateWeightStep(_ text: String) {
        updateData { data in
            data.weightStepText = text
        }
    }

    func dismissSaveError() {
        updateData { data in
            data.isShowingSaveError = false
        }
    }

    func save() async -> Equipment? {
        guard case let .success(data) = editorUiState, data.canSave, let draft = Self.makeDraft(from: data) else {
            return nil
        }
        updateData { data in
            data.isSaving = true
        }
        do {
            return try await saveEquipment.execute(draft: draft, existingId: existingId)
        } catch {
            updateData { data in
                data.isSaving = false
                data.isShowingSaveError = true
            }
            return nil
        }
    }

    func archive() async -> Bool {
        guard let existingId else {
            return false
        }
        do {
            try await archiveEquipment.execute(id: existingId)
            return true
        } catch {
            updateData { data in
                data.isShowingSaveError = true
            }
            return false
        }
    }

    private func updateData(_ change: (inout EquipmentEditorUiData) -> Void) {
        guard case var .success(data) = editorUiState else {
            return
        }
        change(&data)
        editorUiState = .success(data: Self.recalculated(data))
    }

    private static func recalculated(_ data: EquipmentEditorUiData) -> EquipmentEditorUiData {
        var result = data
        result.canSave = !data.isSaving && makeDraft(from: data)?.isValid == true
        return result
    }

    private static func makeDraft(from data: EquipmentEditorUiData) -> EquipmentDraft? {
        guard let weightStep = WeightFormatting.parseKilograms(data.weightStepText) else {
            return nil
        }
        var baseWeight = Weight.zero
        if data.kind.hasBaseWeight {
            guard let parsed = WeightFormatting.parseKilograms(data.baseWeightText) else {
                return nil
            }
            baseWeight = parsed
        }
        return EquipmentDraft(name: data.name, kind: data.kind, baseWeight: baseWeight, weightStep: weightStep)
    }
}
