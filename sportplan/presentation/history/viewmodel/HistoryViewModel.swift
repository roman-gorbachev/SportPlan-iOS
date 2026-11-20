import Domain
import Foundation
import Observation

@Observable
final class HistoryViewModel {
    private static let singleWorkoutCount = 1

    @ObservationIgnored private let observeHistory: ObserveHistoryUseCase
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var overview: HistoryOverview?

    private(set) var historyUiState: HistoryUiState = .loading

    init(observeHistory: ObserveHistoryUseCase, now: @escaping () -> Date) {
        self.observeHistory = observeHistory
        self.now = now
    }

    func observe() async {
        do {
            for try await overview in observeHistory.execute() {
                self.overview = overview
                historyUiState = .success(data: HistoryUiMapper.makeData(overview, now: now(), calendar: .current))
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            historyUiState = .error(error: error)
        }
    }

    func target(forDay date: Date) -> HistoryDayTarget? {
        guard let day = overview?.heatmap.day(containing: date), let firstWorkoutId = day.workoutIds.first else {
            return nil
        }
        guard day.workoutIds.count > Self.singleWorkoutCount else {
            return .workout(id: firstWorkoutId)
        }
        return .day(date: date)
    }
}
