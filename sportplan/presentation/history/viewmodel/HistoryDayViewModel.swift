import Domain
import Foundation
import Observation

@Observable
final class HistoryDayViewModel {
    @ObservationIgnored private let observeHistory: ObserveHistoryUseCase
    @ObservationIgnored private let date: Date
    @ObservationIgnored private let calendar: Calendar

    private(set) var historyDayUiState: HistoryDayUiState = .loading

    init(observeHistory: ObserveHistoryUseCase, date: Date, calendar: Calendar = .current) {
        self.observeHistory = observeHistory
        self.date = date
        self.calendar = calendar
    }

    func observe() async {
        do {
            for try await overview in observeHistory.execute() {
                let items = overview.entries
                    .filter { entry in
                        return calendar.isDate(entry.workout.startedAt, inSameDayAs: date)
                    }
                    .sorted { lhs, rhs in
                        return lhs.workout.startedAt < rhs.workout.startedAt
                    }
                    .map(HistoryUiMapper.makeItem)
                historyDayUiState = .success(data: HistoryDayUiData(title: HistoryFormatting.fullDay(date), items: items))
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            historyDayUiState = .error(error: error)
        }
    }
}
