import Domain
import Foundation
import Observation

@Observable
final class ExercisePickerViewModel {
    @ObservationIgnored private let target: ExercisePickerTarget
    @ObservationIgnored private let observeExerciseLibrary: ObserveExerciseLibraryUseCase
    @ObservationIgnored private let observeProgramDay: ObserveProgramDayUseCase
    @ObservationIgnored private let addExerciseToDay: AddExerciseToDayUseCase
    @ObservationIgnored private let observeActiveWorkout: ObserveActiveWorkoutUseCase
    @ObservationIgnored private let addExerciseToWorkout: AddExerciseToWorkoutUseCase
    @ObservationIgnored private var library: ExerciseLibrary?
    @ObservationIgnored private var addedExerciseIds: Set<UUID>?
    @ObservationIgnored private var pendingIds: Set<UUID> = []
    @ObservationIgnored private var searchQuery = ""
    @ObservationIgnored private var isShowingError = false

    private(set) var pickerUiState: ExercisePickerUiState = .loading

    init(
        target: ExercisePickerTarget,
        observeExerciseLibrary: ObserveExerciseLibraryUseCase,
        observeProgramDay: ObserveProgramDayUseCase,
        addExerciseToDay: AddExerciseToDayUseCase,
        observeActiveWorkout: ObserveActiveWorkoutUseCase,
        addExerciseToWorkout: AddExerciseToWorkoutUseCase
    ) {
        self.target = target
        self.observeExerciseLibrary = observeExerciseLibrary
        self.observeProgramDay = observeProgramDay
        self.addExerciseToDay = addExerciseToDay
        self.observeActiveWorkout = observeActiveWorkout
        self.addExerciseToWorkout = addExerciseToWorkout
    }

    var title: String {
        switch target.destination {
        case let .day(_, shortTitle, _):
            return String(localized: "picker.title \(shortTitle)")
        case .workout:
            return String(localized: "picker.title.workout")
        }
    }

    func observeLibrary() async {
        do {
            for try await library in observeExerciseLibrary.execute() {
                self.library = library
                publish()
            }
        } catch {
            fail(with: error)
        }
    }

    func observeAddedExercises() async {
        do {
            switch target.destination {
            case let .day(id, _, _):
                for try await detail in observeProgramDay.execute(id: id) {
                    updateAddedExercises(detail?.exerciseIds ?? [])
                }
            case .workout:
                for try await workout in observeActiveWorkout.execute() {
                    updateAddedExercises(workout?.exerciseIds ?? [])
                }
            }
        } catch {
            fail(with: error)
        }
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        publish()
    }

    func add(exerciseId: UUID) async {
        guard !pendingIds.contains(exerciseId), addedExerciseIds?.contains(exerciseId) == false else {
            return
        }
        pendingIds.insert(exerciseId)
        publish()
        do {
            switch target.destination {
            case let .day(id, _, _):
                _ = try await addExerciseToDay.execute(exerciseId: exerciseId, dayId: id)
            case .workout:
                try await addExerciseToWorkout.execute(exerciseId: exerciseId)
            }
        } catch {
            pendingIds.remove(exerciseId)
            isShowingError = true
            publish()
        }
    }

    func dismissError() {
        isShowingError = false
        publish()
    }

    private func updateAddedExercises(_ ids: Set<UUID>) {
        addedExerciseIds = ids
        pendingIds.subtract(ids)
        publish()
    }

    private func fail(with error: any Error) {
        guard !Task.isCancelled else {
            return
        }
        pickerUiState = .error(error: error)
    }

    private func publish() {
        guard let library, let addedExerciseIds else {
            return
        }
        let marked = addedExerciseIds.union(pendingIds)
        pickerUiState = .success(data: ExercisePickerUiData(
            sections: library.filtered(by: searchQuery).sections.map { section in
                return PickerSectionItem(
                    category: section.category,
                    title: section.category.libraryTitle,
                    exercises: section.exercises.map { item in
                        let isAdded = marked.contains(item.id)
                        return PickerExerciseItem(
                            id: item.id,
                            name: item.exercise.name,
                            detail: item.equipment?.name ?? item.exercise.metric.listTitle,
                            isAdded: isAdded,
                            accessibilityLabel: accessibilityLabel(name: item.exercise.name, isAdded: isAdded)
                        )
                    }
                )
            },
            isLibraryEmpty: library.isEmpty,
            searchQuery: searchQuery,
            hint: hint,
            emptyMessage: emptyMessage,
            addedLabel: addedLabel,
            isShowingError: isShowingError
        ))
    }

    private var hint: String {
        switch target.destination {
        case .day:
            return String(localized: "picker.hint")
        case .workout:
            return String(localized: "picker.hint.workout")
        }
    }

    private var emptyMessage: String {
        switch target.destination {
        case .day:
            return String(localized: "picker.empty.message")
        case .workout:
            return String(localized: "picker.empty.message.workout")
        }
    }

    private var addedLabel: String {
        switch target.destination {
        case .day:
            return String(localized: "picker.inDay")
        case .workout:
            return String(localized: "picker.inWorkout")
        }
    }

    private func accessibilityLabel(name: String, isAdded: Bool) -> String {
        switch (target.destination, isAdded) {
        case (.day, true):
            return String(localized: "picker.inDay.accessibility \(name)")
        case (.day, false):
            return String(localized: "picker.add.accessibility \(name)")
        case (.workout, true):
            return String(localized: "picker.inWorkout.accessibility \(name)")
        case (.workout, false):
            return String(localized: "picker.add.workout.accessibility \(name)")
        }
    }
}
