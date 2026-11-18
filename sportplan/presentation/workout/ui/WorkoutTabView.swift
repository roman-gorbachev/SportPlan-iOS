import SwiftUI

struct WorkoutTabView: View {
    let container: AppDIContainer
    @Bindable var router: TabRouter
    let onCreateProgram: () -> Void

    var body: some View {
        return NavigationStack(path: $router.path) {
            return WorkoutRoute(
                viewModel: container.buildActiveWorkoutViewModel(),
                makeStartViewModel: container.buildWorkoutStartViewModel,
                makePickerViewModel: container.buildExercisePickerViewModel,
                makeAddExerciseViewModel: container.buildAddExerciseViewModel,
                makeEquipmentEditorViewModel: container.buildEquipmentEditorViewModel,
                onOpenSettings: { router.push(SettingsDestination()) },
                onCreateProgram: onCreateProgram
            )
            .navigationDestination(for: SettingsDestination.self) { _ in
                return SettingsRoute(
                    viewModel: container.buildSettingsViewModel(),
                    onOpenGym: { router.push(GymDestination()) }
                )
            }
            .navigationDestination(for: GymDestination.self) { _ in
                return GymRoute(
                    viewModel: container.buildGymViewModel(),
                    makeEditorViewModel: container.buildEquipmentEditorViewModel
                )
            }
        }
    }
}
