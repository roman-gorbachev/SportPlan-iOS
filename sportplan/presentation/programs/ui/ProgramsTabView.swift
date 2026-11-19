import SwiftUI

struct ProgramsTabView: View {
    let container: AppDIContainer
    @Bindable var router: TabRouter

    var body: some View {
        return NavigationStack(path: $router.path) {
            return ProgramsRoute(
                viewModel: container.buildProgramsViewModel(),
                makeProgramFormViewModel: container.buildProgramFormViewModel,
                makeProgramDayFormViewModel: container.buildProgramDayFormViewModel,
                onOpenLibrary: { router.push(LibraryDestination()) },
                onOpenDay: { dayId in router.push(ProgramDayDestination(dayId: dayId)) }
            )
            .navigationDestination(for: LibraryDestination.self) { _ in
                return LibraryRoute(
                    viewModel: container.buildLibraryViewModel(),
                    makeAddExerciseViewModel: { target in
                        return container.buildAddExerciseViewModel(target: target, dayContext: nil)
                    },
                    makeEquipmentEditorViewModel: container.buildEquipmentEditorViewModel,
                    onOpenExercise: { exerciseId in router.push(ExerciseCardDestination(exerciseId: exerciseId)) }
                )
            }
            .navigationDestination(for: ExerciseCardDestination.self) { destination in
                return ExerciseCardRoute(viewModel: container.buildExerciseCardViewModel(exerciseId: destination.exerciseId))
            }
            .navigationDestination(for: ProgramDayDestination.self) { destination in
                return ProgramDayRoute(
                    viewModel: container.buildProgramDayViewModel(dayId: destination.dayId),
                    makeProgramDayFormViewModel: container.buildProgramDayFormViewModel,
                    makeGoalsViewModel: container.buildPlannedExerciseGoalsViewModel,
                    makePickerViewModel: container.buildExercisePickerViewModel,
                    makeAddExerciseViewModel: container.buildAddExerciseViewModel,
                    makeEquipmentEditorViewModel: container.buildEquipmentEditorViewModel
                )
            }
        }
    }
}
