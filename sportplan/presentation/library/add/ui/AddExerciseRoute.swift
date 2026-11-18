import DesignSystem
import Domain
import SwiftUI

struct AddExerciseRoute: View {
    @State private var viewModel: AddExerciseViewModel
    @State private var path: [AddExerciseStep]
    @State private var editorTarget: EquipmentEditorTarget?
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
            return AddExerciseTypeScreen(onSelect: selectLoadKind)
                .navigationTitle(String(localized: "addExercise.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        return Button(String(localized: "common.cancel"), action: onClose)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        return Text(String(localized: "addExercise.step.first"))
                            .appStyle(Typography.footnote)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    .sharedBackgroundVisibility(.hidden)
                }
                .navigationDestination(for: AddExerciseStep.self) { _ in
                    return details
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

    private var details: some View {
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
    }

    private var canSave: Bool {
        guard case let .success(data) = viewModel.addExerciseUiState else {
            return false
        }
        return data.canSave
    }

    private func selectLoadKind(_ loadKind: ExerciseLoadKind) {
        viewModel.selectLoadKind(loadKind)
        path.append(.details)
    }

    private func createEquipment(for loadKind: ExerciseLoadKind) {
        guard let kind = loadKind.equipmentKind else {
            return
        }
        editorTarget = .new(kind: kind)
    }

    private func save() {
        Task {
            guard await viewModel.save() else {
                return
            }
            onClose()
        }
    }
}
