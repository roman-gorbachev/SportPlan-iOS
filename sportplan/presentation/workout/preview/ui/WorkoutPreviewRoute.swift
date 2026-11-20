import SwiftUI

struct WorkoutPreviewRoute: View {
    @State private var viewModel: WorkoutPreviewViewModel
    private let onStarted: () -> Void

    init(viewModel: WorkoutPreviewViewModel, onStarted: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onStarted = onStarted
    }

    var body: some View {
        return Group {
            switch viewModel.previewUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                WorkoutPreviewScreen(data: data, onStart: start, onDismissError: viewModel.dismissError)
            case .error:
                ErrorStateView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private func start() {
        Task {
            if await viewModel.start() {
                onStarted()
            }
        }
    }
}
