import SwiftUI

struct ExercisePickerRoute: View {
    @State private var viewModel: ExercisePickerViewModel
    @State private var addTarget: AddExerciseTarget?
    private let makeAddExerciseViewModel: (AddExerciseTarget) -> AddExerciseViewModel
    private let makeEquipmentEditorViewModel: (EquipmentEditorTarget) -> EquipmentEditorViewModel
    private let onClose: () -> Void

    init(
        viewModel: ExercisePickerViewModel,
        makeAddExerciseViewModel: @escaping (AddExerciseTarget) -> AddExerciseViewModel,
        makeEquipmentEditorViewModel: @escaping (EquipmentEditorTarget) -> EquipmentEditorViewModel,
        onClose: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeAddExerciseViewModel = makeAddExerciseViewModel
        self.makeEquipmentEditorViewModel = makeEquipmentEditorViewModel
        self.onClose = onClose
    }

    var body: some View {
        return NavigationStack {
            return Group {
                switch viewModel.pickerUiState {
                case .loading:
                    LoadingStateView()
                case let .success(data):
                    ExercisePickerScreen(
                        data: data,
                        onSearchQueryChange: viewModel.updateSearchQuery,
                        onAdd: add,
                        onCreate: { addTarget = .blank },
                        onDismissError: viewModel.dismissError
                    )
                case .error:
                    ErrorStateView()
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    return Button(String(localized: "picker.new"), systemImage: "plus") {
                        addTarget = .blank
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    return Button(String(localized: "common.done"), action: onClose)
                }
            }
        }
        .task {
            await viewModel.observeLibrary()
        }
        .task {
            await viewModel.observeAddedExercises()
        }
        .sheet(item: $addTarget) { target in
            return AddExerciseRoute(
                viewModel: makeAddExerciseViewModel(target),
                makeEquipmentEditorViewModel: makeEquipmentEditorViewModel,
                onClose: { addTarget = nil }
            )
        }
    }

    private func add(_ exerciseId: UUID) {
        Task {
            await viewModel.add(exerciseId: exerciseId)
        }
    }
}
