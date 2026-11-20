import SwiftUI

struct ExerciseArchiveRoute: View {
    @State private var viewModel: ExerciseArchiveViewModel
    private let onEmptied: () -> Void

    init(viewModel: ExerciseArchiveViewModel, onEmptied: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onEmptied = onEmptied
    }

    var body: some View {
        return Group {
            switch viewModel.exerciseArchiveUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                ExerciseArchiveScreen(
                    data: data,
                    onRestore: restore,
                    onDismissRestoreError: viewModel.dismissRestoreError
                )
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
        guard case let .success(data) = viewModel.exerciseArchiveUiState else {
            return false
        }
        return data.items.isEmpty
    }

    private func restore(id: UUID) {
        Task {
            await viewModel.restore(id: id)
        }
    }
}
