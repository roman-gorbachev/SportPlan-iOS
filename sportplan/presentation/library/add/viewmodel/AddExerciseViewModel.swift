import Domain
import Foundation
import Observation

@Observable
final class AddExerciseViewModel {
    private static let placeholderLoadKind: ExerciseLoadKind = .bodyweight

    @ObservationIgnored private let observeEquipmentChoices: ObserveEquipmentChoicesUseCase
    @ObservationIgnored private let createExercise: CreateExerciseUseCase
    @ObservationIgnored private let addExerciseToDay: AddExerciseToDayUseCase
    @ObservationIgnored private let dayContext: AddExerciseDayContext?
    @ObservationIgnored private var dayTargets: PlannedExerciseTargets
    @ObservationIgnored private var draft: ExerciseDraft
    @ObservationIgnored private var equipmentChoices: [Equipment] = []
    @ObservationIgnored private var isSaving = false
    @ObservationIgnored private var isShowingSaveError = false

    let startsAtDetails: Bool

    private(set) var addExerciseUiState: AddExerciseUiState = .loading

    init(
        target: AddExerciseTarget,
        dayContext: AddExerciseDayContext?,
        observeEquipmentChoices: ObserveEquipmentChoicesUseCase,
        createExercise: CreateExerciseUseCase,
        addExerciseToDay: AddExerciseToDayUseCase
    ) {
        self.dayContext = dayContext
        self.observeEquipmentChoices = observeEquipmentChoices
        self.createExercise = createExercise
        self.addExerciseToDay = addExerciseToDay
        var dayTargets = PlannedExerciseTargets(defaultsFor: .weightReps, restSeconds: Exercise.defaultRestSeconds)
        dayTargets.durationSeconds = PlannedExerciseTargets.defaultDurationSeconds
        self.dayTargets = dayTargets
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

    func stepDayTargets(_ step: PlannedExerciseTargetsStep) {
        dayTargets.apply(step, scale: weightScale)
        publish()
    }

    func dismissSaveError() {
        isShowingSaveError = false
        publish()
    }

    func save() async -> Exercise? {
        guard !isSaving, draft.isValid else {
            return nil
        }
        isSaving = true
        publish()
        do {
            let exercise = try await createExercise.execute(draft: draft)
            if let dayContext {
                _ = try await addExerciseToDay.execute(exerciseId: exercise.id, dayId: dayContext.dayId, targets: resolvedDayTargets)
            }
            return exercise
        } catch {
            isSaving = false
            isShowingSaveError = true
            publish()
            return nil
        }
    }

    private var resolvedDayTargets: PlannedExerciseTargets {
        var targets = dayTargets
        targets.restSeconds = draft.restSeconds
        if let weightScale, let startWeight = targets.startWeight, startWeight > weightScale.minimum {
            targets.startWeight = startWeight
        } else {
            targets.startWeight = nil
        }
        return targets.normalized(for: draft.metric)
    }

    private var weightScale: WeightScale? {
        guard draft.loadKind.equipmentKind != nil else {
            return WeightScale(equipment: nil)
        }
        return equipmentChoices.first { equipment in
            return equipment.id == draft.equipmentId
        }.map { equipment in
            return WeightScale(equipment: equipment)
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
            dayContextTitle: dayContext.map { context in
                return String(localized: "addExercise.dayContext \(context.title)")
            },
            dayTargets: dayContext.map { _ in
                return resolvedDayTargets.uiData(for: draft.metric, scale: weightScale)
            },
            canSave: !isSaving && draft.isValid,
            isShowingSaveError: isShowingSaveError
        ))
    }
}
