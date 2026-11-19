import SwiftUI

struct WorkoutRoute: View {
    @State private var viewModel: ActiveWorkoutViewModel
    @State private var pickerTarget: ExercisePickerTarget?
    private let makeStartViewModel: () -> WorkoutStartViewModel
    private let makePickerViewModel: (ExercisePickerTarget) -> ExercisePickerViewModel
    private let makeAddExerciseViewModel: (AddExerciseTarget, AddExerciseDayContext?) -> AddExerciseViewModel
    private let makeEquipmentEditorViewModel: (EquipmentEditorTarget) -> EquipmentEditorViewModel
    private let onOpenSettings: () -> Void
    private let onCreateProgram: () -> Void

    init(
        viewModel: ActiveWorkoutViewModel,
        makeStartViewModel: @escaping () -> WorkoutStartViewModel,
        makePickerViewModel: @escaping (ExercisePickerTarget) -> ExercisePickerViewModel,
        makeAddExerciseViewModel: @escaping (AddExerciseTarget, AddExerciseDayContext?) -> AddExerciseViewModel,
        makeEquipmentEditorViewModel: @escaping (EquipmentEditorTarget) -> EquipmentEditorViewModel,
        onOpenSettings: @escaping () -> Void,
        onCreateProgram: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeStartViewModel = makeStartViewModel
        self.makePickerViewModel = makePickerViewModel
        self.makeAddExerciseViewModel = makeAddExerciseViewModel
        self.makeEquipmentEditorViewModel = makeEquipmentEditorViewModel
        self.onOpenSettings = onOpenSettings
        self.onCreateProgram = onCreateProgram
    }

    var body: some View {
        return Group {
            switch viewModel.activeWorkoutUiState {
            case .loading:
                LoadingStateView()
            case .noWorkout:
                WorkoutStartRoute(
                    viewModel: makeStartViewModel(),
                    onOpenSettings: onOpenSettings,
                    onCreateProgram: onCreateProgram
                )
            case let .success(data):
                ActiveWorkoutScreen(data: data, onAction: handle)
            case .error:
                ErrorStateView()
            }
        }
        .task {
            await viewModel.observe()
        }
        .task {
            await viewModel.observePlateSet()
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

    private func handle(_ action: ActiveWorkoutUserAction) {
        switch action {
        case .openSettings:
            onOpenSettings()
        case .addExercise:
            pickerTarget = viewModel.pickerTarget
        case .requestCancel:
            viewModel.requestCancel()
        case .requestFinish:
            run { await viewModel.requestFinish() }
        case let .editSet(id):
            viewModel.openEditor(setId: id)
        case let .tapSetAction(id):
            run { await viewModel.tapSetAction(setId: id) }
        case let .addSet(workoutExerciseId, isWarmup):
            run { await viewModel.addSet(workoutExerciseId: workoutExerciseId, isWarmup: isWarmup) }
        case let .removeSet(id):
            run { await viewModel.removeSet(id: id) }
        case let .applyProgression(workoutExerciseId):
            run { await viewModel.applyProgression(workoutExerciseId: workoutExerciseId) }
        case let .dismissProgression(workoutExerciseId):
            viewModel.dismissProgression(workoutExerciseId: workoutExerciseId)
        case let .updateNote(text):
            viewModel.updateNote(text)
        case .closeEditor:
            viewModel.closeEditor()
        case .incrementWeight:
            viewModel.incrementEditorWeight()
        case .decrementWeight:
            viewModel.decrementEditorWeight()
        case .incrementReps:
            viewModel.incrementEditorReps()
        case .decrementReps:
            viewModel.decrementEditorReps()
        case .copyLastWorkoutSet:
            viewModel.copyLastWorkoutSet()
        case .saveEditor:
            run { await viewModel.saveEditor() }
        case let .adjustRest(seconds):
            run { await viewModel.adjustRest(seconds: seconds) }
        case .skipRest:
            run { await viewModel.skipRest() }
        case .confirm(let confirmation):
            run { await viewModel.confirm(confirmation) }
        case .dismissConfirmation:
            viewModel.dismissConfirmation()
        case .dismissError:
            viewModel.dismissError()
        }
    }

    private func run(_ operation: @escaping () async -> Void) {
        Task {
            await operation()
        }
    }
}
