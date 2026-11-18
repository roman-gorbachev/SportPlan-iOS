import Domain
import SwiftUI

struct EquipmentEditorRoute: View {
    @State private var viewModel: EquipmentEditorViewModel
    private let onSaved: (Equipment) -> Void
    private let onClose: () -> Void

    init(viewModel: EquipmentEditorViewModel, onSaved: @escaping (Equipment) -> Void, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
        self.onClose = onClose
    }

    var body: some View {
        return NavigationStack {
            return Group {
                switch viewModel.editorUiState {
                case .loading:
                    LoadingStateView()
                case let .success(data):
                    EquipmentEditorScreen(
                        data: data,
                        onNameChange: viewModel.updateName,
                        onKindChange: viewModel.updateKind,
                        onBaseWeightChange: viewModel.updateBaseWeight,
                        onWeightStepChange: viewModel.updateWeightStep,
                        onArchive: archive,
                        onDismissSaveError: viewModel.dismissSaveError
                    )
                case .error:
                    ErrorStateView()
                }
            }
            .navigationTitle(String(localized: "equipment.editor.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    return Button(String(localized: "common.cancel"), action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    return Button(String(localized: "common.done"), action: save)
                        .disabled(!canSave)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var canSave: Bool {
        guard case let .success(data) = viewModel.editorUiState else {
            return false
        }
        return data.canSave
    }

    private func save() {
        Task {
            guard let saved = await viewModel.save() else {
                return
            }
            onSaved(saved)
            onClose()
        }
    }

    private func archive() {
        Task {
            guard await viewModel.archive() else {
                return
            }
            onClose()
        }
    }
}
