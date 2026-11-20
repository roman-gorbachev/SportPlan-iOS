import Domain
import Observation
import SwiftUI

struct ExercisePickerRoute: View {
    @State private var viewModel: ExercisePickerViewModel
    @State private var path: [AddExerciseStep] = []
    @State private var creation = PickerCreation()
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
        return NavigationStack(path: $path) {
            return Group {
                switch viewModel.pickerUiState {
                case .loading:
                    LoadingStateView()
                case let .success(data):
                    ExercisePickerScreen(
                        data: data,
                        onSearchQueryChange: viewModel.updateSearchQuery,
                        onAdd: add,
                        onCreate: startCreating,
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
                    return Button(String(localized: "picker.new"), systemImage: "plus", action: startCreating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    return Button(String(localized: "common.done"), action: onClose)
                }
            }
            .navigationDestination(for: AddExerciseStep.self) { step in
                return Group {
                    if let addViewModel = creation.viewModel {
                        AddExerciseStepDestination(
                            step: step,
                            viewModel: addViewModel,
                            makeEquipmentEditorViewModel: makeEquipmentEditorViewModel,
                            onCancel: nil,
                            onContinue: { path.append(.details) },
                            onSaved: finishCreating
                        )
                    }
                }
            }
        }
        .task {
            await viewModel.observeLibrary()
        }
        .task {
            await viewModel.observeAddedExercises()
        }
    }

    private func add(_ exerciseId: UUID) {
        Task {
            await viewModel.add(exerciseId: exerciseId)
        }
    }

    private func startCreating() {
        creation.viewModel = makeAddExerciseViewModel(.blank)
        path = [.type]
    }

    private func finishCreating(_ exercise: Exercise) {
        Task {
            if await viewModel.addCreatedExercise(id: exercise.id) {
                onClose()
            } else {
                path = []
            }
        }
    }
}

@Observable
private final class PickerCreation {
    var viewModel: AddExerciseViewModel?
}
