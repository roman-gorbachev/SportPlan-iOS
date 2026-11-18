import SwiftUI

struct ProgramDayFormRoute: View {
    @State private var viewModel: ProgramDayFormViewModel
    private let onClose: () -> Void

    init(viewModel: ProgramDayFormViewModel, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onClose = onClose
    }

    var body: some View {
        return NavigationStack {
            return Group {
                switch viewModel.dayFormUiState {
                case .loading:
                    LoadingStateView()
                case let .success(data):
                    ProgramDayFormScreen(
                        data: data,
                        onLabelChange: viewModel.updateLabel,
                        onNameChange: viewModel.updateName,
                        onDelete: viewModel.requestDelete,
                        onConfirmDelete: confirmDelete,
                        onCancelDelete: viewModel.cancelDelete,
                        onDismissError: viewModel.dismissError
                    )
                case .error:
                    ErrorStateView()
                }
            }
            .navigationTitle(isNew ? String(localized: "programDay.form.title.new") : String(localized: "programDay.form.title.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    return Button(String(localized: "common.cancel"), action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    return Button(isNew ? String(localized: "programDay.form.add") : String(localized: "common.done"), action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var isNew: Bool {
        guard case let .success(data) = viewModel.dayFormUiState else {
            return true
        }
        return data.isNew
    }

    private var canSave: Bool {
        guard case let .success(data) = viewModel.dayFormUiState else {
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

    private func confirmDelete() {
        Task {
            guard await viewModel.confirmDelete() else {
                return
            }
            onClose()
        }
    }
}
