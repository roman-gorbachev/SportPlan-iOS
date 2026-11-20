import Foundation
import SwiftUI

struct HistoryDayRoute: View {
    @State private var viewModel: HistoryDayViewModel
    private let onOpenWorkout: (UUID) -> Void
    private let onEmptied: () -> Void

    init(viewModel: HistoryDayViewModel, onOpenWorkout: @escaping (UUID) -> Void, onEmptied: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenWorkout = onOpenWorkout
        self.onEmptied = onEmptied
    }

    var body: some View {
        return Group {
            switch viewModel.historyDayUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                HistoryDayScreen(data: data, onOpenWorkout: onOpenWorkout)
            case .error:
                ErrorStateView()
            }
        }
        .onChange(of: isEmpty) { _, isEmpty in
            if isEmpty {
                onEmptied()
            }
        }
        .task {
            await viewModel.observe()
        }
    }

    private var isEmpty: Bool {
        guard case let .success(data) = viewModel.historyDayUiState else {
            return false
        }
        return data.isEmpty
    }
}
