import Domain
import Foundation
import Observation

@Observable
final class PlannedExerciseGoalsViewModel {
    @ObservationIgnored private let target: PlannedExerciseGoalsTarget
    @ObservationIgnored private let updateTargets: UpdatePlannedExerciseTargetsUseCase
    @ObservationIgnored private let removePlannedExercise: RemovePlannedExerciseUseCase
    @ObservationIgnored private var targets: PlannedExerciseTargets
    @ObservationIgnored private var isSaving = false
    @ObservationIgnored private var isShowingError = false

    private(set) var goalsUiState: PlannedExerciseGoalsUiState = .loading

    init(
        target: PlannedExerciseGoalsTarget,
        updateTargets: UpdatePlannedExerciseTargetsUseCase,
        removePlannedExercise: RemovePlannedExerciseUseCase
    ) {
        self.target = target
        self.updateTargets = updateTargets
        self.removePlannedExercise = removePlannedExercise
        targets = target.targets
        publish()
    }

    func step(_ step: PlannedExerciseTargetsStep) {
        targets.apply(step)
        publish()
    }

    func save() async -> Bool {
        guard !isSaving else {
            return false
        }
        isSaving = true
        publish()
        do {
            try await updateTargets.execute(id: target.plannedExerciseId, targets: targets)
            return true
        } catch {
            fail()
            return false
        }
    }

    func remove() async -> Bool {
        guard !isSaving else {
            return false
        }
        isSaving = true
        publish()
        do {
            try await removePlannedExercise.execute(id: target.plannedExerciseId)
            return true
        } catch {
            fail()
            return false
        }
    }

    func dismissError() {
        isShowingError = false
        publish()
    }

    private func fail() {
        isSaving = false
        isShowingError = true
        publish()
    }

    private func publish() {
        let exerciseRest = RestFormatting.clock(seconds: target.exerciseRestSeconds)
        goalsUiState = .success(data: PlannedExerciseGoalsUiData(
            exerciseName: target.exerciseName,
            subtitle: String(localized: "goals.subtitle \(target.dayTitle)"),
            targets: targets.uiData,
            restHint: String(localized: "goals.rest.hint \(exerciseRest)"),
            canSave: !isSaving,
            isShowingError: isShowingError
        ))
    }
}
