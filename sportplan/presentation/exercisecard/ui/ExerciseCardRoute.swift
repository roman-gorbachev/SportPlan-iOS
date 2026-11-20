import Foundation
import SwiftUI

struct ExerciseCardRoute: View {
    @State private var viewModel: ExerciseCardViewModel
    @State private var isEditing = false
    private let exerciseId: UUID
    private let makeEditorViewModel: (UUID) -> ExerciseEditorViewModel
    private let onArchived: () -> Void

    init(
        viewModel: ExerciseCardViewModel,
        exerciseId: UUID,
        makeEditorViewModel: @escaping (UUID) -> ExerciseEditorViewModel,
        onArchived: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.exerciseId = exerciseId
        self.makeEditorViewModel = makeEditorViewModel
        self.onArchived = onArchived
    }

    var body: some View {
        return Group {
            switch viewModel.exerciseCardUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                ExerciseCardScreen(data: data, onSelectMetric: viewModel.selectMetric)
            case .error:
                ErrorStateView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                return Button(String(localized: "exercise.edit")) {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            return ExerciseEditorRoute(
                viewModel: makeEditorViewModel(exerciseId),
                onClose: { isEditing = false },
                onArchived: archived
            )
        }
        .task {
            await viewModel.observe()
        }
    }

    private func archived() {
        isEditing = false
        onArchived()
    }
}
