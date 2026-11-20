import Domain
import SwiftUI

struct LibraryRoute: View {
    @State private var viewModel: LibraryViewModel
    @State private var addTarget: AddExerciseTarget?
    @State private var editorTarget: ExerciseEditorTarget?
    private let makeAddExerciseViewModel: (AddExerciseTarget) -> AddExerciseViewModel
    private let makeEquipmentEditorViewModel: (EquipmentEditorTarget) -> EquipmentEditorViewModel
    private let makeExerciseEditorViewModel: (UUID) -> ExerciseEditorViewModel
    private let onOpenExercise: (UUID) -> Void

    init(
        viewModel: LibraryViewModel,
        makeAddExerciseViewModel: @escaping (AddExerciseTarget) -> AddExerciseViewModel,
        makeEquipmentEditorViewModel: @escaping (EquipmentEditorTarget) -> EquipmentEditorViewModel,
        makeExerciseEditorViewModel: @escaping (UUID) -> ExerciseEditorViewModel,
        onOpenExercise: @escaping (UUID) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeAddExerciseViewModel = makeAddExerciseViewModel
        self.makeEquipmentEditorViewModel = makeEquipmentEditorViewModel
        self.makeExerciseEditorViewModel = makeExerciseEditorViewModel
        self.onOpenExercise = onOpenExercise
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
                    onOpenExercise: onOpenExercise,
                    onEdit: { exerciseId in editorTarget = ExerciseEditorTarget(exerciseId: exerciseId) },
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
        .sheet(item: $editorTarget) { target in
            return ExerciseEditorRoute(
                viewModel: makeExerciseEditorViewModel(target.exerciseId),
                onClose: { editorTarget = nil },
                onArchived: { editorTarget = nil }
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
