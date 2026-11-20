import Domain
import SwiftUI

struct AddExerciseRoute: View {
    @State private var viewModel: AddExerciseViewModel
    @State private var path: [AddExerciseStep]
    private let makeEquipmentEditorViewModel: (EquipmentEditorTarget) -> EquipmentEditorViewModel
    private let onClose: () -> Void

    init(
        viewModel: AddExerciseViewModel,
        makeEquipmentEditorViewModel: @escaping (EquipmentEditorTarget) -> EquipmentEditorViewModel,
        onClose: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        _path = State(initialValue: viewModel.startsAtDetails ? [.details] : [])
        self.makeEquipmentEditorViewModel = makeEquipmentEditorViewModel
        self.onClose = onClose
    }

    var body: some View {
        return NavigationStack(path: $path) {
            return destination(.type)
                .navigationDestination(for: AddExerciseStep.self) { step in
                    return destination(step)
                }
        }
    }

    private func destination(_ step: AddExerciseStep) -> AddExerciseStepDestination {
        return AddExerciseStepDestination(
            step: step,
            viewModel: viewModel,
            makeEquipmentEditorViewModel: makeEquipmentEditorViewModel,
            onCancel: onClose,
            onContinue: { path.append(.details) },
            onSaved: { _ in onClose() }
        )
    }
}
