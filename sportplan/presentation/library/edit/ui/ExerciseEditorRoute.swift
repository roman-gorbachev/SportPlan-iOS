import SwiftUI

struct ExerciseEditorRoute: View {
    @State private var viewModel: ExerciseEditorViewModel
    private let onClose: () -> Void
    private let onArchived: () -> Void

    init(viewModel: ExerciseEditorViewModel, onClose: @escaping () -> Void, onArchived: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onClose = onClose
        self.onArchived = onArchived
    }

    var body: some View {
        return NavigationStack {
            return Group {
                switch viewModel.exerciseEditorUiState {
                case .loading:
                    LoadingStateView()
                case let .success(data):
                    ExerciseEditorScreen(
                        data: data,
                        onNameChange: viewModel.updateName,
                        onDescriptionChange: viewModel.updateDescription,
                        onSelectEquipment: viewModel.selectEquipment,
                        onMetricChange: viewModel.updateMetric,
                        onIncrementRest: viewModel.incrementRest,
                        onDecrementRest: viewModel.decrementRest,
                        onArchive: viewModel.requestArchive,
                        onConfirmArchive: confirmArchive,
                        onCancelArchive: viewModel.cancelArchive,
                        onDismissSaveError: viewModel.dismissSaveError,
                        onDismissArchiveError: viewModel.dismissArchiveError
                    )
                    .navigationTitle(data.title)
                case .error:
                    ErrorStateView()
                }
            }
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
        guard case let .success(data) = viewModel.exerciseEditorUiState else {
            return false
        }
        return data.canSave
    }

    private func save() {
        Task {
            if await viewModel.save() {
                onClose()
            }
        }
    }

    private func confirmArchive() {
        Task {
            if await viewModel.confirmArchive() {
                onArchived()
            }
        }
    }
}
