import Domain
import Foundation
import Observation

@Observable
final class WorkoutDetailsViewModel {
    @ObservationIgnored private let observeFinishedWorkout: ObserveFinishedWorkoutUseCase
    @ObservationIgnored private let deleteWorkout: DeleteWorkoutUseCase
    @ObservationIgnored private let workoutId: UUID
    @ObservationIgnored private var detail: FinishedWorkoutDetail?
    @ObservationIgnored private var isShowingDeleteError = false

    private(set) var workoutDetailsUiState: WorkoutDetailsUiState = .loading

    init(observeFinishedWorkout: ObserveFinishedWorkoutUseCase, deleteWorkout: DeleteWorkoutUseCase, workoutId: UUID) {
        self.observeFinishedWorkout = observeFinishedWorkout
        self.deleteWorkout = deleteWorkout
        self.workoutId = workoutId
    }

    func observe() async {
        do {
            for try await detail in observeFinishedWorkout.execute(workoutId: workoutId) {
                guard let detail else {
                    self.detail = nil
                    workoutDetailsUiState = .deleted
                    continue
                }
                self.detail = detail
                publish()
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            workoutDetailsUiState = .error(error: error)
        }
    }

    func delete() async {
        do {
            try await deleteWorkout.execute(workoutId: workoutId)
        } catch {
            isShowingDeleteError = true
            publish()
        }
    }

    func dismissDeleteError() {
        isShowingDeleteError = false
        publish()
    }

    private func publish() {
        guard let detail else {
            return
        }
        workoutDetailsUiState = .success(data: WorkoutDetailsUiMapper.makeData(detail, isShowingDeleteError: isShowingDeleteError))
    }
}
