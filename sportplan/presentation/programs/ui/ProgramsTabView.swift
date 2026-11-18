import SwiftUI

struct ProgramsTabView: View {
    let container: AppDIContainer
    @Bindable var router: TabRouter

    var body: some View {
        return NavigationStack(path: $router.path) {
            return ProgramsRoute(
                viewModel: container.buildProgramsViewModel(),
                onOpenLibrary: { router.push(LibraryDestination()) }
            )
            .navigationDestination(for: LibraryDestination.self) { _ in
                return LibraryRoute(
                    viewModel: container.buildLibraryViewModel(),
                    makeAddExerciseViewModel: container.buildAddExerciseViewModel,
                    makeEquipmentEditorViewModel: container.buildEquipmentEditorViewModel
                )
            }
        }
    }
}
