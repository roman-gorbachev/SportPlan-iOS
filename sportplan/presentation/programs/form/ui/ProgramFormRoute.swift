import SwiftUI

struct ProgramFormRoute: View {
    @State private var viewModel: ProgramFormViewModel
    private let onClose: () -> Void

    init(viewModel: ProgramFormViewModel, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onClose = onClose
    }

    var body: some View {
        return NavigationStack {
            return Group {
                switch viewModel.programFormUiState {
                case .loading:
                    LoadingStateView()
                case let .success(data):
                    ProgramFormScreen(
                        data: data,
                        onNameChange: viewModel.updateName,
                        onDayLabelChange: viewModel.updateDayLabel,
                        onDayNameChange: viewModel.updateDayName,
                        onDismissSaveError: viewModel.dismissSaveError
                    )
                case .error:
                    ErrorStateView()
                }
            }
            .navigationTitle(isCreating ? String(localized: "programForm.title.new") : String(localized: "programForm.title.rename"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    return Button(String(localized: "common.cancel"), action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    return Button(isCreating ? String(localized: "programForm.create") : String(localized: "common.done"), action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var isCreating: Bool {
        guard case let .success(data) = viewModel.programFormUiState else {
            return false
        }
        return data.isCreating
    }

    private var canSave: Bool {
        guard case let .success(data) = viewModel.programFormUiState else {
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
}
