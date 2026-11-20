import Foundation
import SwiftUI

struct HistoryRoute: View {
    @State private var viewModel: HistoryViewModel
    private let onOpenWorkout: (UUID) -> Void
    private let onOpenDay: (Date) -> Void
    private let onStartWorkout: () -> Void

    init(
        viewModel: HistoryViewModel,
        onOpenWorkout: @escaping (UUID) -> Void,
        onOpenDay: @escaping (Date) -> Void,
        onStartWorkout: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenWorkout = onOpenWorkout
        self.onOpenDay = onOpenDay
        self.onStartWorkout = onStartWorkout
    }

    var body: some View {
        return Group {
            switch viewModel.historyUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                HistoryScreen(
                    data: data,
                    onSelectDay: selectDay,
                    onOpenWorkout: onOpenWorkout,
                    onStartWorkout: onStartWorkout
                )
            case .error:
                ErrorStateView()
            }
        }
        .navigationTitle(AppTab.history.title)
        .task {
            await viewModel.observe()
        }
    }

    private func selectDay(_ date: Date) {
        guard let target = viewModel.target(forDay: date) else {
            return
        }
        switch target {
        case let .workout(id):
            onOpenWorkout(id)
        case let .day(date):
            onOpenDay(date)
        }
    }
}
