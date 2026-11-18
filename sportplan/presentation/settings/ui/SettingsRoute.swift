import SwiftUI

struct SettingsRoute: View {
    @State private var viewModel: SettingsViewModel
    private let onOpenGym: () -> Void

    init(viewModel: SettingsViewModel, onOpenGym: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenGym = onOpenGym
    }

    var body: some View {
        return Group {
            switch viewModel.settingsUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                SettingsScreen(data: data, onOpenGym: onOpenGym)
            case .error:
                ErrorStateView()
            }
        }
        .navigationTitle(String(localized: "settings.title"))
        .task {
            await viewModel.observe()
        }
    }
}
