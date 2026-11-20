import SwiftUI

struct SettingsRoute: View {
    @State private var viewModel: SettingsViewModel
    private let onOpenGym: () -> Void
    private let onImported: () -> Void

    init(viewModel: SettingsViewModel, onOpenGym: @escaping () -> Void, onImported: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenGym = onOpenGym
        self.onImported = onImported
    }

    var body: some View {
        return Group {
            switch viewModel.settingsUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                SettingsScreen(
                    data: data,
                    exportItem: BackupExportItem(makeExport: { [viewModel] in
                        return try await viewModel.export()
                    }),
                    onOpenGym: onOpenGym,
                    onImportFile: { url in
                        Task {
                            await viewModel.readImport(fileURL: url)
                        }
                    },
                    onImportFileFailed: viewModel.failImportFile,
                    onConfirmImport: viewModel.confirmImport,
                    onCancelImport: viewModel.cancelImport,
                    onDismissImportResult: {
                        if viewModel.dismissImportResult() {
                            onImported()
                        }
                    }
                )
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
