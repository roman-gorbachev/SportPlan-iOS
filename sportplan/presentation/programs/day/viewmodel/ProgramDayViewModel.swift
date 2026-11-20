import Domain
import Foundation
import Observation

@Observable
final class ProgramDayViewModel {
    @ObservationIgnored private let dayId: UUID
    @ObservationIgnored private let observeProgramDay: ObserveProgramDayUseCase
    @ObservationIgnored private let removePlannedExercise: RemovePlannedExerciseUseCase
    @ObservationIgnored private let reorderPlannedExercises: ReorderPlannedExercisesUseCase
    @ObservationIgnored private var detail: ProgramDayDetail?
    @ObservationIgnored private var exercises: [PlannedExerciseItem] = []
    @ObservationIgnored private var isShowingError = false

    private(set) var dayUiState: ProgramDayUiState = .loading

    init(
        dayId: UUID,
        observeProgramDay: ObserveProgramDayUseCase,
        removePlannedExercise: RemovePlannedExerciseUseCase,
        reorderPlannedExercises: ReorderPlannedExercisesUseCase
    ) {
        self.dayId = dayId
        self.observeProgramDay = observeProgramDay
        self.removePlannedExercise = removePlannedExercise
        self.reorderPlannedExercises = reorderPlannedExercises
    }

    func observe() async {
        do {
            for try await detail in observeProgramDay.execute(id: dayId) {
                guard let detail else {
                    dayUiState = .missing
                    return
                }
                self.detail = detail
                exercises = detail.exercises
                publish()
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            dayUiState = .error(error: error)
        }
    }

    var dayFormTarget: ProgramDayFormTarget? {
        guard let detail else {
            return nil
        }
        return .edit(day: detail.day, programName: detail.programName)
    }

    var pickerTarget: ExercisePickerTarget? {
        guard let detail else {
            return nil
        }
        return ExercisePickerTarget(destination: .day(
            id: detail.day.id,
            shortTitle: ProgramFormatting.dayShortTitle(detail.day),
            fullTitle: ProgramFormatting.dayFullTitle(detail.day)
        ))
    }

    func goalsTarget(plannedExerciseId: UUID) -> PlannedExerciseGoalsTarget? {
        guard let detail, let item = exercises.first(where: { item in return item.id == plannedExerciseId }) else {
            return nil
        }
        return PlannedExerciseGoalsTarget(
            plannedExerciseId: item.id,
            exercise: item.exercise,
            dayTitle: ProgramFormatting.dayFullTitle(detail.day),
            targets: item.plannedExercise.targets
        )
    }

    func remove(at offsets: IndexSet) async {
        let ids = offsets.map { index in
            return exercises[index].id
        }
        exercises = exercises.enumerated().filter { element in
            return !offsets.contains(element.offset)
        }.map(\.element)
        publish()
        do {
            for id in ids {
                try await removePlannedExercise.execute(id: id)
            }
        } catch {
            showError()
        }
    }

    func move(from source: IndexSet, to destination: Int) async {
        let moving = source.map { index in
            return exercises[index]
        }
        var remaining = exercises.enumerated().filter { element in
            return !source.contains(element.offset)
        }.map(\.element)
        let insertionIndex = destination - source.filter { index in
            return index < destination
        }.count
        remaining.insert(contentsOf: moving, at: insertionIndex)
        exercises = remaining
        publish()
        do {
            try await reorderPlannedExercises.execute(dayId: dayId, orderedIds: exercises.map(\.id))
        } catch {
            showError()
        }
    }

    func dismissError() {
        isShowingError = false
        publish()
    }

    private func showError() {
        isShowingError = true
        if let detail {
            exercises = detail.exercises
        }
        publish()
    }

    private func publish() {
        guard let detail else {
            return
        }
        dayUiState = .success(data: ProgramDayUiData(
            title: detail.day.name,
            subtitle: ProgramFormatting.daySubtitle(programName: detail.programName, day: detail.day),
            fullTitle: ProgramFormatting.dayFullTitle(detail.day),
            exercises: exercises.map { item in
                return PlannedExerciseRowItem(
                    id: item.id,
                    name: item.exercise.exercise.name,
                    targetText: ProgramFormatting.targetText(item.plannedExercise.targets),
                    targetAccessibilityText: ProgramFormatting.targetSpokenText(item.plannedExercise.targets),
                    detailText: ProgramFormatting.detailText(item)
                )
            },
            isShowingError: isShowingError
        ))
    }
}
