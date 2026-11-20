import Domain
import Foundation
import Observation

@Observable
final class ExerciseArchiveViewModel {
    @ObservationIgnored private let observeArchivedExercises: ObserveArchivedExercisesUseCase
    @ObservationIgnored private let restoreExercise: RestoreExerciseUseCase
    @ObservationIgnored private var exercises: [ArchivedExercise]?
    @ObservationIgnored private var isShowingRestoreError = false

    private(set) var exerciseArchiveUiState: ExerciseArchiveUiState = .loading

    init(observeArchivedExercises: ObserveArchivedExercisesUseCase, restoreExercise: RestoreExerciseUseCase) {
        self.observeArchivedExercises = observeArchivedExercises
        self.restoreExercise = restoreExercise
    }

    func observe() async {
        do {
            for try await exercises in observeArchivedExercises.execute() {
                self.exercises = exercises
                publish()
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            exerciseArchiveUiState = .error(error: error)
        }
    }

    func restore(id: UUID) async {
        do {
            try await restoreExercise.execute(id: id)
        } catch {
            isShowingRestoreError = true
            publish()
        }
    }

    func dismissRestoreError() {
        isShowingRestoreError = false
        publish()
    }

    private func publish() {
        guard let exercises else {
            return
        }
        exerciseArchiveUiState = .success(data: ExerciseArchiveUiData(
            items: exercises.map(Self.makeItem),
            isShowingRestoreError: isShowingRestoreError
        ))
    }

    private static func makeItem(_ archived: ArchivedExercise) -> ArchivedExerciseItem {
        let name = archived.exercise.exercise.name
        let load = archived.exercise.equipment?.name ?? archived.exercise.loadKind.title
        let detail: String
        if archived.workoutCount > 0 {
            let workouts = String(localized: "archive.row.workouts \(archived.workoutCount)")
            detail = String(localized: "library.row.detail \(load) \(workouts)")
        } else {
            detail = load
        }
        return ArchivedExerciseItem(
            id: archived.id,
            name: name,
            detail: detail,
            restoreAccessibilityLabel: String(localized: "archive.restore.accessibility \(name)")
        )
    }
}
