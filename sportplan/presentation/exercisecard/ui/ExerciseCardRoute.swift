import SwiftUI

struct ExerciseCardRoute: View {
    @State private var viewModel: ExerciseCardViewModel

    init(viewModel: ExerciseCardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        return Group {
            switch viewModel.exerciseCardUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                ExerciseCardScreen(data: data, onSelectMetric: viewModel.selectMetric)
            case .error:
                ErrorStateView()
            }
        }
        .task {
            await viewModel.observe()
        }
    }
}
