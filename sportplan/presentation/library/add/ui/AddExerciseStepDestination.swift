import Domain
import SwiftUI

struct AddExerciseStepDestination: View {
    let step: AddExerciseStep
    let viewModel: AddExerciseViewModel
    let makeEquipmentEditorViewModel: (EquipmentEditorTarget) -> EquipmentEditorViewModel
    let onCancel: (() -> Void)?
    let onContinue: () -> Void
    let onSaved: (Exercise) -> Void

    var body: some View {
        return Group {
            switch step {
            case .type:
                AddExerciseTypeStep(viewModel: viewModel, onCancel: onCancel, onContinue: onContinue)
            case .details:
                AddExerciseDetailsStep(
                    viewModel: viewModel,
                    makeEquipmentEditorViewModel: makeEquipmentEditorViewModel,
                    onSaved: onSaved
                )
            }
        }
    }
}
