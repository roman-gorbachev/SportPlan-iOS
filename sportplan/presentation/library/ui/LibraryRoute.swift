import Domain
import SwiftUI

struct LibraryRoute: View {
    @State private var viewModel: LibraryViewModel
    @State private var addTarget: AddExerciseTarget?
    private let makeAddExerciseViewModel: (AddExerciseTarget) -> AddExerciseViewModel
    private let makeEquipmentEditorViewModel: (EquipmentEditorTarget) -> EquipmentEditorViewModel

    init(
        viewModel: LibraryViewModel,
        makeAddExerciseViewModel: @escaping (AddExerciseTarget) -> AddExerciseViewModel,
        makeEquipmentEditorViewModel: @escaping (EquipmentEditorTarget) -> EquipmentEditorViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeAddExerciseViewModel = makeAddExerciseViewModel
        self.makeEquipmentEditorViewModel = makeEquipmentEditorViewModel
    }

    var body: some View {
        return Group {
            switch viewModel.libraryUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                LibraryScreen(
                    data: data,
                    onSearchQueryChange: viewModel.updateSearchQuery,
                    onQuickAdd: { quickExercise in addTarget = .quick(quickExercise) },
                    onAddCustom: { addTarget = .blank },
                    onArchive: requestArchive,
                    onConfirmArchive: confirmArchive,
                    onCancelArchive: viewModel.cancelArchive,
                    onDismissArchiveError: viewModel.dismissArchiveError
                )
            case .error:
                ErrorStateView()
            }
        }
        .navigationTitle(String(localized: "library.title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                return Button(action: { addTarget = .blank }) {
                    return Image(systemName: "plus")
                }
                .accessibilityLabel(String(localized: "addExercise.title"))
            }
        }
        .task {
            await viewModel.observe()
        }
        .sheet(item: $addTarget) { target in
            return AddExerciseRoute(
                viewModel: makeAddExerciseViewModel(target),
                makeEquipmentEditorViewModel: makeEquipmentEditorViewModel,
                onClose: { addTarget = nil }
            )
        }
    }

    private func requestArchive(id: UUID) {
        Task {
            await viewModel.requestArchive(id: id)
        }
    }

    private func confirmArchive(id: UUID) {
        Task {
            await viewModel.confirmArchive(id: id)
        }
    }
}
