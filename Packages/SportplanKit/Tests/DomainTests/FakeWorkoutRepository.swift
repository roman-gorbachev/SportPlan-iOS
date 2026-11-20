import Domain
import Foundation
import Synchronization

final class FakeWorkoutRepository: WorkoutRepository {
    private struct State {
        var workouts: [Workout] = []
        var workoutExercises: [WorkoutExercise] = []
        var sets: [SetEntry] = []
        var library: [UUID: LibraryExercise] = [:]
        var previousSets: [UUID: [SetEntry]] = [:]
        var previousWorkoutExercises: [UUID: WorkoutExercise] = [:]
        var lastWorkoutDates: [UUID: Date] = [:]
        var updateSetsCallCount = 0
    }

    private let state = Mutex(State())

    init(
        library: [LibraryExercise] = [],
        previousSets: [UUID: [SetEntry]] = [:],
        previousWorkoutExercises: [UUID: WorkoutExercise] = [:],
        lastWorkoutDates: [UUID: Date] = [:]
    ) {
        state.withLock { state in
            for item in library {
                state.library[item.id] = item
            }
            state.previousSets = previousSets
            state.previousWorkoutExercises = previousWorkoutExercises
            state.lastWorkoutDates = lastWorkoutDates
        }
    }

    var updateSetsCallCount: Int {
        return state.withLock { state in
            return state.updateSetsCallCount
        }
    }

    var workouts: [Workout] {
        return state.withLock { state in
            return state.workouts
        }
    }

    var workoutExercises: [WorkoutExercise] {
        return state.withLock { state in
            return state.workoutExercises
        }
    }

    var sets: [SetEntry] {
        return state.withLock { state in
            return state.sets.sorted { lhs, rhs in
                return lhs.position < rhs.position
            }
        }
    }

    func observeActive() -> AsyncThrowingStream<ActiveWorkout?, any Error> {
        let active = state.withLock { state in
            return Self.makeActive(state)
        }
        return AsyncThrowingStream { continuation in
            continuation.yield(active)
            continuation.finish()
        }
    }

    func activeWorkout() async throws -> ActiveWorkout? {
        return state.withLock { state in
            return Self.makeActive(state)
        }
    }

    func start(_ workout: Workout, exercises: [WorkoutExercise], sets: [SetEntry]) async throws {
        try state.withLock { state in
            guard !state.workouts.contains(where: { stored in return stored.finishedAt == nil }) else {
                throw WorkoutError.alreadyActive
            }
            state.workouts.append(workout)
            state.workoutExercises += exercises
            state.sets += sets
        }
    }

    func addExercise(_ workoutExercise: WorkoutExercise, sets: [SetEntry]) async throws {
        state.withLock { state in
            state.workoutExercises.append(workoutExercise)
            state.sets += sets
        }
    }

    func addSet(_ entry: SetEntry) async throws {
        state.withLock { state in
            for index in state.sets.indices
            where state.sets[index].workoutExerciseId == entry.workoutExerciseId && state.sets[index].position >= entry.position {
                state.sets[index].position += 1
            }
            state.sets.append(entry)
        }
    }

    func updateSet(_ entry: SetEntry) async throws {
        try state.withLock { state in
            guard let index = state.sets.firstIndex(where: { stored in return stored.id == entry.id }) else {
                throw WorkoutError.notFound
            }
            var updated = entry
            updated.position = state.sets[index].position
            state.sets[index] = updated
        }
    }

    func updateSets(_ entries: [SetEntry]) async throws {
        state.withLock { state in
            state.updateSetsCallCount += 1
            for entry in entries {
                guard let index = state.sets.firstIndex(where: { stored in return stored.id == entry.id }) else {
                    continue
                }
                var updated = entry
                updated.position = state.sets[index].position
                state.sets[index] = updated
            }
        }
    }

    func removeSet(id: UUID) async throws {
        state.withLock { state in
            state.sets.removeAll { entry in
                return entry.id == id
            }
        }
    }

    func updateNote(workoutId: UUID, note: String?) async throws {
        state.withLock { state in
            guard let index = state.workouts.firstIndex(where: { workout in return workout.id == workoutId }) else {
                return
            }
            state.workouts[index].note = note
        }
    }

    func updateRest(workoutId: UUID, rest: RestPeriod?) async throws {
        state.withLock { state in
            guard let index = state.workouts.firstIndex(where: { workout in return workout.id == workoutId }) else {
                return
            }
            state.workouts[index].rest = rest
        }
    }

    func finish(workoutId: UUID, at date: Date) async throws {
        state.withLock { state in
            state.sets.removeAll { entry in
                return !entry.isCompleted
            }
            state.workoutExercises.removeAll { item in
                return !state.sets.contains { entry in
                    return entry.workoutExerciseId == item.id
                }
            }
            guard let index = state.workouts.firstIndex(where: { workout in return workout.id == workoutId }) else {
                return
            }
            state.workouts[index].finishedAt = date
            state.workouts[index].rest = nil
        }
    }

    func cancel(workoutId: UUID) async throws {
        state.withLock { state in
            let exerciseIds = Set(state.workoutExercises.filter { item in
                return item.workoutId == workoutId
            }.map(\.id))
            state.sets.removeAll { entry in
                return exerciseIds.contains(entry.workoutExerciseId)
            }
            state.workoutExercises.removeAll { item in
                return item.workoutId == workoutId
            }
            state.workouts.removeAll { workout in
                return workout.id == workoutId
            }
        }
    }

    func previousSets(exerciseId: UUID) async throws -> [SetEntry] {
        return state.withLock { state in
            return state.previousSets[exerciseId, default: []]
        }
    }

    func previousWorkoutExercise(exerciseId: UUID) async throws -> WorkoutExercise? {
        return state.withLock { state in
            return state.previousWorkoutExercises[exerciseId]
        }
    }

    func lastWorkoutDate(programDayId: UUID) async throws -> Date? {
        return state.withLock { state in
            return state.lastWorkoutDates[programDayId]
        }
    }

    func observeExerciseHistory(exerciseId: UUID) -> AsyncThrowingStream<ExerciseHistory?, any Error> {
        let history = state.withLock { state in
            return Self.makeHistory(state, exerciseId: exerciseId)
        }
        return AsyncThrowingStream { continuation in
            continuation.yield(history)
            continuation.finish()
        }
    }

    private static func makeHistory(_ state: State, exerciseId: UUID) -> ExerciseHistory? {
        guard let exercise = state.library[exerciseId] else {
            return nil
        }
        let sessions = state.workouts.compactMap { workout -> ExerciseSession? in
            let itemIds = Set(state.workoutExercises.filter { item in
                return item.workoutId == workout.id && item.exerciseId == exerciseId
            }.map(\.id))
            let sets = state.sets.filter { entry in
                return itemIds.contains(entry.workoutExerciseId) && entry.isCompleted && !entry.isWarmup
            }
            guard !sets.isEmpty else {
                return nil
            }
            return ExerciseSession(workoutId: workout.id, date: workout.startedAt, sets: sets)
        }
        return ExerciseHistory(exercise: exercise, sessions: sessions)
    }

    private static func makeActive(_ state: State) -> ActiveWorkout? {
        guard let workout = state.workouts.first(where: { workout in return workout.finishedAt == nil }) else {
            return nil
        }
        let exercises = state.workoutExercises
            .filter { item in
                return item.workoutId == workout.id
            }
            .sorted { lhs, rhs in
                return lhs.position < rhs.position
            }
            .compactMap { item -> ActiveWorkoutExercise? in
                guard let exercise = state.library[item.exerciseId] else {
                    return nil
                }
                let sets = state.sets
                    .filter { entry in
                        return entry.workoutExerciseId == item.id
                    }
                    .sorted { lhs, rhs in
                        return lhs.position < rhs.position
                    }
                return ActiveWorkoutExercise(
                    workoutExercise: item,
                    exercise: exercise,
                    sets: sets,
                    previousSets: state.previousSets[item.exerciseId, default: []],
                    previousWorkoutExercise: state.previousWorkoutExercises[item.exerciseId]
                )
            }
        return ActiveWorkout(workout: workout, programName: nil, exercises: exercises)
    }
}
