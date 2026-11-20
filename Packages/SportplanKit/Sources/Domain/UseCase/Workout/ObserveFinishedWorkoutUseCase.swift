import Foundation

public struct ObserveFinishedWorkoutUseCase: Sendable {
    private let repository: any WorkoutRepository

    public init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    public func execute(workoutId: UUID) -> AsyncThrowingStream<FinishedWorkoutDetail?, any Error> {
        return repository.observeFinished().mapElements { workouts in
            guard let workout = workouts.first(where: { workout in return workout.id == workoutId }) else {
                return nil
            }
            return FinishedWorkoutDetail(workout: workout, recordSetIds: WorkoutRecords.recordSetIds(in: workouts))
        }
    }
}
