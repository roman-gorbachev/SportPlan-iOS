import SwiftUI

struct WorkoutStartRoute: View {
    @State private var viewModel: WorkoutStartViewModel
    private let onOpenSettings: () -> Void
    private let onCreateProgram: () -> Void

    init(viewModel: WorkoutStartViewModel, onOpenSettings: @escaping () -> Void, onCreateProgram: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenSettings = onOpenSettings
        self.onCreateProgram = onCreateProgram
    }

    var body: some View {
        return Group {
            switch viewModel.startUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                WorkoutStartScreen(
                    data: data,
                    onStartDay: startDay,
                    onStartEmpty: startEmpty,
                    onCreateProgram: onCreateProgram,
                    onDismissError: viewModel.dismissError
                )
            case .error:
                ErrorStateView()
            }
        }
        .navigationTitle(AppTab.workout.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                return Button(action: onOpenSettings) {
                    return Label(String(localized: "settings.title"), systemImage: "gearshape")
                }
            }
        }
        .task {
            await viewModel.observeProgramList()
        }
    }

    private func startDay(_ dayId: UUID) {
        Task {
            await viewModel.start(dayId: dayId)
        }
    }

    private func startEmpty() {
        Task {
            await viewModel.startEmpty()
        }
    }
}
