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
                onOpenDay: { dayId in router.push(WorkoutPreviewDestination(dayId: dayId)) },
                onOpenSettings: { router.push(SettingsDestination()) },
                onOpenExercise: { exerciseId in router.push(ExerciseCardDestination(exerciseId: exerciseId)) },
                onCreateProgram: onCreateProgram
            )
            .navigationDestination(for: WorkoutPreviewDestination.self) { destination in
                return WorkoutPreviewRoute(
                    viewModel: container.buildWorkoutPreviewViewModel(dayId: destination.dayId),
                    onStarted: { router.popToRoot() }
                )
            }
            .navigationDestination(for: ExerciseCardDestination.self) { destination in
                return ExerciseCardRoute(
                    viewModel: container.buildExerciseCardViewModel(exerciseId: destination.exerciseId),
                    exerciseId: destination.exerciseId,
                    makeEditorViewModel: container.buildExerciseEditorViewModel,
                    onArchived: { router.pop() }
                )
            }
            .navigationDestination(for: SettingsDestination.self) { _ in
                return SettingsRoute(
                    viewModel: container.buildSettingsViewModel(),
                    onOpenGym: { router.push(GymDestination()) }
                )
            }
            .navigationDestination(for: GymDestination.self) { _ in
                return GymRoute(
                    viewModel: container.buildGymViewModel(),
                    makeEditorViewModel: container.buildEquipmentEditorViewModel,
                    makePlateEditorViewModel: container.buildPlateEditorViewModel
                )
            }
        }
    }
}
