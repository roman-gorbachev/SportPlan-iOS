import SwiftUI

struct HistoryTabView: View {
    let container: AppDIContainer
    @Bindable var router: TabRouter
    let onStartWorkout: () -> Void

    var body: some View {
        return NavigationStack(path: $router.path) {
            return HistoryRoute(
                viewModel: container.buildHistoryViewModel(),
                onOpenWorkout: { workoutId in router.push(HistoryWorkoutDestination(workoutId: workoutId)) },
                onOpenDay: { date in router.push(HistoryDayDestination(date: date)) },
                onStartWorkout: onStartWorkout
            )
            .navigationDestination(for: HistoryDayDestination.self) { destination in
                return HistoryDayRoute(
                    viewModel: container.buildHistoryDayViewModel(date: destination.date),
                    onOpenWorkout: { workoutId in router.push(HistoryWorkoutDestination(workoutId: workoutId)) },
                    onEmptied: { router.pop() }
                )
            }
            .navigationDestination(for: HistoryWorkoutDestination.self) { destination in
                return WorkoutDetailsRoute(
                    viewModel: container.buildWorkoutDetailsViewModel(workoutId: destination.workoutId),
                    onOpenExercise: { exerciseId in router.push(ExerciseCardDestination(exerciseId: exerciseId)) },
                    onDeleted: { router.pop() }
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
        }
    }
}
