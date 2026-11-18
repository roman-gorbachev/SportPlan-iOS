import SwiftUI

struct ProgramDayRoute: View {
    @State private var viewModel: ProgramDayViewModel
    @State private var editMode: EditMode = .inactive
    @State private var dayFormTarget: ProgramDayFormTarget?
    @State private var goalsTarget: PlannedExerciseGoalsTarget?
    @State private var pickerTarget: ExercisePickerTarget?
    @Environment(\.dismiss) private var dismiss
    private let makeProgramDayFormViewModel: (ProgramDayFormTarget) -> ProgramDayFormViewModel
    private let makeGoalsViewModel: (PlannedExerciseGoalsTarget) -> PlannedExerciseGoalsViewModel
    private let makePickerViewModel: (ExercisePickerTarget) -> ExercisePickerViewModel
    private let makeAddExerciseViewModel: (AddExerciseTarget, AddExerciseDayContext?) -> AddExerciseViewModel
    private let makeEquipmentEditorViewModel: (EquipmentEditorTarget) -> EquipmentEditorViewModel

    init(
        viewModel: ProgramDayViewModel,
        makeProgramDayFormViewModel: @escaping (ProgramDayFormTarget) -> ProgramDayFormViewModel,
        makeGoalsViewModel: @escaping (PlannedExerciseGoalsTarget) -> PlannedExerciseGoalsViewModel,
        makePickerViewModel: @escaping (ExercisePickerTarget) -> ExercisePickerViewModel,
        makeAddExerciseViewModel: @escaping (AddExerciseTarget, AddExerciseDayContext?) -> AddExerciseViewModel,
        makeEquipmentEditorViewModel: @escaping (EquipmentEditorTarget) -> EquipmentEditorViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeProgramDayFormViewModel = makeProgramDayFormViewModel
        self.makeGoalsViewModel = makeGoalsViewModel
        self.makePickerViewModel = makePickerViewModel
        self.makeAddExerciseViewModel = makeAddExerciseViewModel
        self.makeEquipmentEditorViewModel = makeEquipmentEditorViewModel
    }

    var body: some View {
        return Group {
            switch viewModel.dayUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                ProgramDayScreen(
                    data: data,
                    isEditing: editMode.isEditing,
                    onSelectExercise: selectExercise,
                    onAddExercise: { pickerTarget = viewModel.pickerTarget },
                    onEditDay: { dayFormTarget = viewModel.dayFormTarget },
                    onDelete: remove,
                    onMove: move,
                    onDismissError: viewModel.dismissError
                )
                .navigationTitle(data.title)
                .navigationSubtitle(data.subtitle)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        return Button(editMode.isEditing ? String(localized: "common.done") : String(localized: "programDay.edit"), action: toggleEditing)
                    }
                }
            case .missing:
                Color.clear
                    .task {
                        dismiss()
                    }
            case .error:
                ErrorStateView()
            }
        }
        .environment(\.editMode, $editMode)
        .task {
            await viewModel.observe()
        }
        .sheet(item: $dayFormTarget) { target in
            return ProgramDayFormRoute(viewModel: makeProgramDayFormViewModel(target), onClose: { dayFormTarget = nil })
        }
        .sheet(item: $goalsTarget) { target in
            return PlannedExerciseGoalsRoute(viewModel: makeGoalsViewModel(target), onClose: { goalsTarget = nil })
        }
        .sheet(item: $pickerTarget) { target in
            return ExercisePickerRoute(
                viewModel: makePickerViewModel(target),
                makeAddExerciseViewModel: { addTarget in return makeAddExerciseViewModel(addTarget, target.dayContext) },
                makeEquipmentEditorViewModel: makeEquipmentEditorViewModel,
                onClose: { pickerTarget = nil }
            )
        }
    }

    private func toggleEditing() {
        withAnimation {
            editMode = editMode.isEditing ? .inactive : .active
        }
    }

    private func selectExercise(_ id: UUID) {
        goalsTarget = viewModel.goalsTarget(plannedExerciseId: id)
    }

    private func remove(at offsets: IndexSet) {
        Task {
            await viewModel.remove(at: offsets)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        Task {
            await viewModel.move(from: source, to: destination)
        }
    }
}
