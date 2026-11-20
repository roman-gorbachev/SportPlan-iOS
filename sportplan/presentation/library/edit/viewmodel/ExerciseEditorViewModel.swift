import Domain
import Foundation
import Observation

@Observable
final class ExerciseEditorViewModel {
    @ObservationIgnored private let exerciseId: UUID
    @ObservationIgnored private let loadExerciseEditor: LoadExerciseEditorUseCase
    @ObservationIgnored private let observeEquipmentChoices: ObserveEquipmentChoicesUseCase
    @ObservationIgnored private let updateExercise: UpdateExerciseUseCase
    @ObservationIgnored private let archiveExercise: ArchiveExerciseUseCase
    @ObservationIgnored private var snapshot: ExerciseEditorSnapshot?
    @ObservationIgnored private var draft: ExerciseDraft?
    @ObservationIgnored private var equipmentChoices: [Equipment] = []
    @ObservationIgnored private var isSaving = false
    @ObservationIgnored private var pendingArchive: LibraryArchiveConfirmation?
    @ObservationIgnored private var isShowingSaveError = false
    @ObservationIgnored private var isShowingArchiveError = false

    private(set) var exerciseEditorUiState: ExerciseEditorUiState = .loading

    init(
        exerciseId: UUID,
        loadExerciseEditor: LoadExerciseEditorUseCase,
        observeEquipmentChoices: ObserveEquipmentChoicesUseCase,
        updateExercise: UpdateExerciseUseCase,
        archiveExercise: ArchiveExerciseUseCase
    ) {
        self.exerciseId = exerciseId
        self.loadExerciseEditor = loadExerciseEditor
        self.observeEquipmentChoices = observeEquipmentChoices
        self.updateExercise = updateExercise
        self.archiveExercise = archiveExercise
    }

    func load() async {
        do {
            let snapshot = try await loadedSnapshot()
            guard let kind = snapshot.loadKind.equipmentKind else {
                return
            }
            for try await equipment in observeEquipmentChoices.execute(kind: kind) {
                equipmentChoices = equipment
                publish()
            }
        } catch {
            guard !Task.isCancelled, snapshot == nil else {
                return
            }
            exerciseEditorUiState = .error(error: error)
        }
    }

    func updateName(_ name: String) {
        draft?.name = name
        publish()
    }

    func updateDescription(_ description: String) {
        draft?.description = description
        publish()
    }

    func selectEquipment(id: UUID) {
        draft?.equipmentId = id
        publish()
    }

    func updateMetric(_ metric: ExerciseMetric) {
        guard let snapshot, !snapshot.isMetricLocked, snapshot.loadKind.allowsDuration else {
            return
        }
        draft?.metric = metric
        publish()
    }

    func incrementRest() {
        draft?.incrementRest()
        publish()
    }

    func decrementRest() {
        draft?.decrementRest()
        publish()
    }

    func save() async -> Bool {
        guard let snapshot, let draft, !isSaving, draft.isValid else {
            return false
        }
        guard draft != snapshot.draft else {
            return true
        }
        isSaving = true
        publish()
        do {
            try await updateExercise.execute(exerciseId: exerciseId, draft: draft)
            isSaving = false
            return true
        } catch {
            isSaving = false
            isShowingSaveError = true
            publish()
            return false
        }
    }

    func requestArchive() {
        guard let snapshot else {
            return
        }
        pendingArchive = LibraryArchiveConfirmation(
            exerciseId: exerciseId,
            exerciseName: snapshot.exercise.name,
            programDayCount: snapshot.programDayCount
        )
        publish()
    }

    func cancelArchive() {
        pendingArchive = nil
        publish()
    }

    func confirmArchive() async -> Bool {
        pendingArchive = nil
        publish()
        do {
            try await archiveExercise.execute(id: exerciseId)
            return true
        } catch {
            isShowingArchiveError = true
            publish()
            return false
        }
    }

    func dismissSaveError() {
        isShowingSaveError = false
        publish()
    }

    func dismissArchiveError() {
        isShowingArchiveError = false
        publish()
    }

    private func loadedSnapshot() async throws -> ExerciseEditorSnapshot {
        if let snapshot {
            return snapshot
        }
        let snapshot = try await loadExerciseEditor.execute(exerciseId: exerciseId)
        self.snapshot = snapshot
        draft = snapshot.draft
        publish()
        return snapshot
    }

    private func publish() {
        guard let snapshot, let draft else {
            return
        }
        exerciseEditorUiState = .success(data: ExerciseEditorUiData(
            title: snapshot.exercise.name,
            name: draft.name,
            description: draft.description,
            equipmentHeader: snapshot.loadKind.editorEquipmentHeader,
            equipmentChoices: equipmentChoices.map { equipment in
                return AddExerciseEquipmentItem(
                    id: equipment.id,
                    name: equipment.name,
                    weightsText: EquipmentFormatting.weightsText(equipment),
                    weightsAccessibilityText: EquipmentFormatting.weightsAccessibilityText(equipment),
                    isSelected: equipment.id == draft.equipmentId
                )
            },
            equipmentLockHint: snapshot.hasCompletedSets ? snapshot.loadKind.editorEquipmentLockHint : nil,
            showsMetric: snapshot.loadKind.allowsDuration,
            metric: draft.metric,
            isMetricLocked: snapshot.isMetricLocked,
            restText: RestFormatting.clock(seconds: draft.restSeconds),
            restAccessibilityText: RestFormatting.spoken(seconds: draft.restSeconds),
            canIncrementRest: draft.canIncrementRest,
            canDecrementRest: draft.canDecrementRest,
            canSave: !isSaving && draft.isValid,
            pendingArchive: pendingArchive,
            isShowingSaveError: isShowingSaveError,
            isShowingArchiveError: isShowingArchiveError
        ))
    }
}
