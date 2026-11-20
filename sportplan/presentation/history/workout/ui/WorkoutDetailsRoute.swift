import DesignSystem
import Foundation
import SwiftUI

struct WorkoutDetailsRoute: View {
    @State private var viewModel: WorkoutDetailsViewModel
    @State private var isConfirmingDelete = false
    private let onOpenExercise: (UUID) -> Void
    private let onDeleted: () -> Void

    init(viewModel: WorkoutDetailsViewModel, onOpenExercise: @escaping (UUID) -> Void, onDeleted: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenExercise = onOpenExercise
        self.onDeleted = onDeleted
    }

    var body: some View {
        return Group {
            switch viewModel.workoutDetailsUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                WorkoutDetailsScreen(
                    data: data,
                    onOpenExercise: onOpenExercise,
                    onDismissDeleteError: viewModel.dismissDeleteError
                )
            case .deleted:
                Palette.background
                    .ignoresSafeArea()
            case .error:
                ErrorStateView()
            }
        }
        .toolbar {
            if isLoaded {
                ToolbarItem(placement: .primaryAction) {
                    return Menu {
                        Button(role: .destructive) {
                            isConfirmingDelete = true
                        } label: {
                            return Label(String(localized: "history.details.delete"), systemImage: "trash")
                        }
                    } label: {
                        return Label(String(localized: "history.details.actions"), systemImage: "ellipsis")
                    }
                    .confirmationDialog(
                        String(localized: "history.details.delete.title"),
                        isPresented: $isConfirmingDelete,
                        titleVisibility: .visible
                    ) {
                        Button(String(localized: "history.details.delete.confirm"), role: .destructive) {
                            Task {
                                await viewModel.delete()
                            }
                        }
                    } message: {
                        Text(String(localized: "history.details.delete.message"))
                    }
                }
            }
        }
        .onChange(of: isDeleted) { _, isDeleted in
            if isDeleted {
                onDeleted()
            }
        }
        .task {
            await viewModel.observe()
        }
    }

    private var isLoaded: Bool {
        guard case .success = viewModel.workoutDetailsUiState else {
            return false
        }
        return true
    }

    private var isDeleted: Bool {
        guard case .deleted = viewModel.workoutDetailsUiState else {
            return false
        }
        return true
    }
}
