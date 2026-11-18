import SwiftUI

struct PlannedExerciseGoalsRoute: View {
    @State private var viewModel: PlannedExerciseGoalsViewModel
    private let onClose: () -> Void

    init(viewModel: PlannedExerciseGoalsViewModel, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onClose = onClose
    }

    var body: some View {
        return NavigationStack {
            return Group {
                switch viewModel.goalsUiState {
                case .loading:
                    LoadingStateView()
                case let .success(data):
                    PlannedExerciseGoalsScreen(
                        data: data,
                        onStep: viewModel.step,
                        onRemove: remove,
                        onDismissError: viewModel.dismissError
                    )
                    .navigationTitle(data.exerciseName)
                    .navigationSubtitle(data.subtitle)
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
    }

    private var canSave: Bool {
        guard case let .success(data) = viewModel.goalsUiState else {
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

    private func remove() {
        Task {
            guard await viewModel.remove() else {
                return
            }
            onClose()
        }
    }
}
