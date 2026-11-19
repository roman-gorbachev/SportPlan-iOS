import DesignSystem
import SwiftUI

struct RootView: View {
    let container: AppDIContainer

    @State private var restTimerViewModel: RestTimerViewModel
    @State private var selectedTab: AppTab = .workout
    @State private var workoutRouter = TabRouter()
    @State private var programsRouter = TabRouter()
    @State private var historyRouter = TabRouter()

    init(container: AppDIContainer) {
        self.container = container
        _restTimerViewModel = State(initialValue: container.buildRestTimerViewModel())
    }

    var body: some View {
        return TabView(selection: $selectedTab) {
            Tab(AppTab.workout.title, systemImage: AppTab.workout.systemImage, value: AppTab.workout) {
                return WorkoutTabView(container: container, router: workoutRouter, onCreateProgram: { selectedTab = .programs })
            }
            Tab(AppTab.programs.title, systemImage: AppTab.programs.systemImage, value: AppTab.programs) {
                return ProgramsTabView(container: container, router: programsRouter)
            }
            Tab(AppTab.history.title, systemImage: AppTab.history.systemImage, value: AppTab.history) {
                return HistoryTabView(router: historyRouter)
            }
        }
        .tint(Palette.accent)
        .modifier(RestTimerAccessoryModifier(viewModel: restTimerViewModel, onOpen: { selectedTab = .workout }))
        .task {
            await container.observeActiveWorkout()
        }
        .task {
            await container.observeWorkoutActivity()
        }
    }
}
