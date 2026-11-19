import SwiftUI

struct PlateEditorRoute: View {
    @State private var viewModel: PlateEditorViewModel
    private let onClose: () -> Void

    init(viewModel: PlateEditorViewModel, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onClose = onClose
    }

    var body: some View {
        return NavigationStack {
            return Group {
                switch viewModel.editorUiState {
                case .loading:
                    LoadingStateView()
                case let .success(data):
                    PlateEditorScreen(
                        data: data,
                        onWeightChange: viewModel.updateWeight,
                        onColorChange: viewModel.selectColor,
                        onDelete: delete,
                        onDismissSaveError: viewModel.dismissSaveError
                    )
                case .error:
                    ErrorStateView()
                }
            }
            .navigationTitle(String(localized: "plate.editor.title"))
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
            guard await viewModel.save() else {
                return
            }
            onClose()
        }
    }

    private func delete() {
        Task {
            guard await viewModel.delete() else {
                return
            }
            onClose()
        }
    }
}
