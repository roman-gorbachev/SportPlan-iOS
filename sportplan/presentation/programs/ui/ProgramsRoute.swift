import SwiftUI

struct ProgramsRoute: View {
    @State private var viewModel: ProgramsViewModel
    @State private var formTarget: ProgramFormTarget?
    @State private var dayFormTarget: ProgramDayFormTarget?
    private let makeProgramFormViewModel: (ProgramFormTarget) -> ProgramFormViewModel
    private let makeProgramDayFormViewModel: (ProgramDayFormTarget) -> ProgramDayFormViewModel
    private let onOpenLibrary: () -> Void
    private let onOpenDay: (UUID) -> Void

    init(
        viewModel: ProgramsViewModel,
        makeProgramFormViewModel: @escaping (ProgramFormTarget) -> ProgramFormViewModel,
        makeProgramDayFormViewModel: @escaping (ProgramDayFormTarget) -> ProgramDayFormViewModel,
        onOpenLibrary: @escaping () -> Void,
        onOpenDay: @escaping (UUID) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeProgramFormViewModel = makeProgramFormViewModel
        self.makeProgramDayFormViewModel = makeProgramDayFormViewModel
        self.onOpenLibrary = onOpenLibrary
        self.onOpenDay = onOpenDay
    }

    var body: some View {
        return Group {
            switch viewModel.programsUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                ProgramsScreen(
                    data: data,
                    onOpenLibrary: onOpenLibrary,
                    onCreateProgram: { formTarget = .create },
                    onRenameProgram: { program in formTarget = .rename(id: program.id, name: program.name) },
                    onDeleteProgram: viewModel.requestDelete,
                    onConfirmDelete: confirmDelete,
                    onCancelDelete: viewModel.cancelDelete,
                    onOpenDay: onOpenDay,
                    onAddDay: { program in dayFormTarget = .new(programId: program.id, programName: program.name) },
                    onDismissError: viewModel.dismissError
                )
            case .error:
                ErrorStateView()
            }
        }
        .navigationTitle(AppTab.programs.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                return Button(action: { formTarget = .create }) {
                    return Image(systemName: "plus")
                }
                .accessibilityLabel(String(localized: "programs.new"))
            }
        }
        .task {
            await viewModel.observeLibrary()
        }
        .task {
            await viewModel.observeProgramList()
        }
        .sheet(item: $formTarget) { target in
            return ProgramFormRoute(viewModel: makeProgramFormViewModel(target), onClose: { formTarget = nil })
        }
        .sheet(item: $dayFormTarget) { target in
            return ProgramDayFormRoute(viewModel: makeProgramDayFormViewModel(target), onClose: { dayFormTarget = nil })
        }
    }

    private func confirmDelete(id: UUID) {
        Task {
            await viewModel.confirmDelete(id: id)
        }
    }
}
