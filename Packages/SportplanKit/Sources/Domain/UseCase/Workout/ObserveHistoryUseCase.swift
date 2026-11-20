import Foundation

public struct ObserveHistoryUseCase: Sendable {
    private let repository: any WorkoutRepository
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        repository: any WorkoutRepository,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.now = now
        self.calendar = calendar
    }

    public func execute() -> AsyncThrowingStream<HistoryOverview, any Error> {
        let now = self.now
        let calendar = self.calendar
        return repository.observeFinished().mapElements { workouts in
            return HistoryOverview(workouts: workouts, today: now(), calendar: calendar)
        }
    }
}
