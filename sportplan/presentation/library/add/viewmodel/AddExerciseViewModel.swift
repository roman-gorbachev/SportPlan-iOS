import Domain
import Foundation
import Observation

@Observable
final class AddExerciseViewModel {
    private static let placeholderLoadKind: ExerciseLoadKind = .bodyweight

    @ObservationIgnored private let observeEquipmentChoices: ObserveEquipmentChoicesUseCase
    @ObservationIgnored private let createExercise: CreateExerciseUseCase
    @ObservationIgnored private var draft: ExerciseDraft
    @ObservationIgnored private var equipmentChoices: [Equipment] = []
    @ObservationIgnored private var isSaving = false
    @ObservationIgnored private var isShowingSaveError = false

    let startsAtDetails: Bool

    private(set) var addExerciseUiState: AddExerciseUiState = .loading

    init(
        target: AddExerciseTarget,
        observeEquipmentChoices: ObserveEquipmentChoicesUseCase,
        createExercise: CreateExerciseUseCase
    ) {
        self.observeEquipmentChoices = observeEquipmentChoices
        self.createExercise = createExercise
        switch target {
        case .blank:
            draft = ExerciseDraft(loadKind: Self.placeholderLoadKind)
            startsAtDetails = false
        case let .quick(quickExercise):
            draft = ExerciseDraft(quickExercise: quickExercise, name: quickExercise.title)
            startsAtDetails = true
        }
        publish()
    }

    func selectLoadKind(_ loadKind: ExerciseLoadKind) {
        if draft.loadKind != loadKind {
            equipmentChoices = []
        }
        draft.loadKind = loadKind
        publish()
    }

    func observeEquipment() async {
        guard let kind = draft.loadKind.equipmentKind else {
            return
        }
        do {
            for try await equipment in observeEquipmentChoices.execute(kind: kind) {
                guard draft.loadKind.equipmentKind == kind else {
                    return
                }
                equipmentChoices = equipment
                if draft.equipmentId == nil, equipment.count == 1 {
                    draft.equipmentId = equipment.first?.id
                }
                publish()
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            addExerciseUiState = .error(error: error)
        }
    }

    func updateName(_ name: String) {
        draft.name = name
        publish()
    }

    func selectEquipment(id: UUID) {
        draft.equipmentId = id
        publish()
    }

    func selectCreatedEquipment(_ equipment: Equipment) {
        guard draft.loadKind.equipmentKind == equipment.kind else {
            return
        }
        if !equipmentChoices.contains(where: { choice in
            return choice.id == equipment.id
        }) {
            equipmentChoices.append(equipment)
        }
        draft.equipmentId = equipment.id
        publish()
    }

    func updateMetric(_ metric: ExerciseMetric) {
        guard metric == .weightReps || draft.loadKind.allowsDuration else {
            return
        }
        draft.metric = metric
        publish()
    }

    func incrementRest() {
        draft.incrementRest()
        publish()
    }

    func decrementRest() {
        draft.decrementRest()
        publish()
    }

    func updateDescription(_ description: String) {
        draft.description = description
        publish()
    }

    func dismissSaveError() {
        isShowingSaveError = false
        publish()
    }

    func save() async -> Bool {
        guard !isSaving, draft.isValid else {
            return false
        }
        isSaving = true
        publish()
        do {
            _ = try await createExercise.execute(draft: draft)
            return true
        } catch {
            isSaving = false
            isShowingSaveError = true
            publish()
            return false
        }
    }

    private func publish() {
        addExerciseUiState = .success(data: AddExerciseUiData(
            loadKind: draft.loadKind,
            name: draft.name,
            equipmentChoices: equipmentChoices.map { equipment in
                return AddExerciseEquipmentItem(
                    id: equipment.id,
                    name: equipment.name,
                    weightsText: EquipmentFormatting.weightsText(equipment),
                    weightsAccessibilityText: EquipmentFormatting.weightsAccessibilityText(equipment),
                    isSelected: equipment.id == draft.equipmentId
                )
            },
            metric: draft.metric,
            showsMetricPicker: draft.loadKind.allowsDuration,
            restText: RestFormatting.clock(seconds: draft.restSeconds),
            restAccessibilityText: RestFormatting.spoken(seconds: draft.restSeconds),
            canIncrementRest: draft.canIncrementRest,
            canDecrementRest: draft.canDecrementRest,
            description: draft.description,
            canSave: !isSaving && draft.isValid,
            isShowingSaveError: isShowingSaveError
        ))
    }
}
