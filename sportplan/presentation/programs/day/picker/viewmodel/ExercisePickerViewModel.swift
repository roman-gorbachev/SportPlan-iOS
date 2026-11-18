import Domain
import Foundation
import Observation

@Observable
final class ExercisePickerViewModel {
    @ObservationIgnored private let target: ExercisePickerTarget
    @ObservationIgnored private let observeExerciseLibrary: ObserveExerciseLibraryUseCase
    @ObservationIgnored private let observeProgramDay: ObserveProgramDayUseCase
    @ObservationIgnored private let addExerciseToDay: AddExerciseToDayUseCase
    @ObservationIgnored private var library: ExerciseLibrary?
    @ObservationIgnored private var exerciseIdsInDay: Set<UUID>?
    @ObservationIgnored private var pendingIds: Set<UUID> = []
    @ObservationIgnored private var searchQuery = ""
    @ObservationIgnored private var isShowingError = false

    private(set) var pickerUiState: ExercisePickerUiState = .loading

    init(
        target: ExercisePickerTarget,
        observeExerciseLibrary: ObserveExerciseLibraryUseCase,
        observeProgramDay: ObserveProgramDayUseCase,
        addExerciseToDay: AddExerciseToDayUseCase
    ) {
        self.target = target
        self.observeExerciseLibrary = observeExerciseLibrary
        self.observeProgramDay = observeProgramDay
        self.addExerciseToDay = addExerciseToDay
    }

    var title: String {
        return String(localized: "picker.title \(target.shortTitle)")
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

    func observeDay() async {
        do {
            for try await detail in observeProgramDay.execute(id: target.dayId) {
                exerciseIdsInDay = detail?.exerciseIds ?? []
                pendingIds.subtract(exerciseIdsInDay ?? [])
                publish()
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
        guard !pendingIds.contains(exerciseId), exerciseIdsInDay?.contains(exerciseId) == false else {
            return
        }
        pendingIds.insert(exerciseId)
        publish()
        do {
            _ = try await addExerciseToDay.execute(exerciseId: exerciseId, dayId: target.dayId)
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

    private func fail(with error: any Error) {
        guard !Task.isCancelled else {
            return
        }
        pickerUiState = .error(error: error)
    }

    private func publish() {
        guard let library, let exerciseIdsInDay else {
            return
        }
        let marked = exerciseIdsInDay.union(pendingIds)
        pickerUiState = .success(data: ExercisePickerUiData(
            sections: library.filtered(by: searchQuery).sections.map { section in
                return PickerSectionItem(
                    category: section.category,
                    title: section.category.libraryTitle,
                    exercises: section.exercises.map { item in
                        return PickerExerciseItem(
                            id: item.id,
                            name: item.exercise.name,
                            detail: item.equipment?.name ?? item.exercise.metric.listTitle,
                            isInDay: marked.contains(item.id)
                        )
                    }
                )
            },
            isLibraryEmpty: library.isEmpty,
            searchQuery: searchQuery,
            isShowingError: isShowingError
        ))
    }
}
