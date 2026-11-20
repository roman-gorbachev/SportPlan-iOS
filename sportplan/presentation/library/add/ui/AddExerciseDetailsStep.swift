import DesignSystem
import Domain
import SwiftUI

struct AddExerciseDetailsStep: View {
    let viewModel: AddExerciseViewModel
    let makeEquipmentEditorViewModel: (EquipmentEditorTarget) -> EquipmentEditorViewModel
    let onSaved: (Exercise) -> Void

    @State private var editorTarget: EquipmentEditorTarget?

    var body: some View {
        return Group {
            switch viewModel.addExerciseUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                AddExerciseDetailsScreen(
                    data: data,
                    onNameChange: viewModel.updateName,
                    onSelectEquipment: viewModel.selectEquipment,
                    onCreateEquipment: { createEquipment(for: data.loadKind) },
                    onMetricChange: viewModel.updateMetric,
                    onIncrementRest: viewModel.incrementRest,
                    onDecrementRest: viewModel.decrementRest,
                    onDescriptionChange: viewModel.updateDescription,
                    onDayTargetsStep: viewModel.stepDayTargets,
                    onDismissSaveError: viewModel.dismissSaveError
                )
                .navigationTitle(data.loadKind.title)
                .task(id: data.loadKind) {
                    await viewModel.observeEquipment()
                }
            case .error:
                ErrorStateView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                return Button(String(localized: "addExercise.add"), action: save)
                    .disabled(!canSave)
            }
        }
        .sheet(item: $editorTarget) { target in
            return EquipmentEditorRoute(
                viewModel: makeEquipmentEditorViewModel(target),
                onSaved: viewModel.selectCreatedEquipment,
                onClose: { editorTarget = nil }
            )
        }
    }

    private var canSave: Bool {
        guard case let .success(data) = viewModel.addExerciseUiState else {
            return false
        }
        return data.canSave
    }

    private func createEquipment(for loadKind: ExerciseLoadKind) {
        guard let kind = loadKind.equipmentKind else {
            return
        }
        editorTarget = .new(kind: kind)
    }

    private func save() {
        Task {
            guard let exercise = await viewModel.save() else {
                return
            }
            onSaved(exercise)
        }
    }
}
