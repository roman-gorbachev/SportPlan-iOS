import SwiftUI

struct ProgramsRoute: View {
    @State private var viewModel: ProgramsViewModel
    private let onOpenLibrary: () -> Void

    init(viewModel: ProgramsViewModel, onOpenLibrary: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenLibrary = onOpenLibrary
    }

    var body: some View {
        return Group {
            switch viewModel.programsUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                ProgramsScreen(data: data, onOpenLibrary: onOpenLibrary)
            case .error:
                ErrorStateView()
            }
        }
        .navigationTitle(AppTab.programs.title)
        .task {
            await viewModel.observe()
        }
    }
}
