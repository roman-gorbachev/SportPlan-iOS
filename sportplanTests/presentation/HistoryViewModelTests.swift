import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct HistoryViewModelTests {
    private static let pollInterval = Duration.milliseconds(10)
    private static let pollAttempts = 300
    private static let secondsPerHour: TimeInterval = 3_600
    private static let secondsPerDay: TimeInterval = 86_400

    private struct Context {
        let database: AppDatabase
        let exercise: Exercise
        let dayStart: Date
        let now: Date
    }

    private static func makeContext() async throws -> Context {
        let database = try DatabaseFixtures.makeDatabase()
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        try await database.writer.write { db in
            try ExerciseRecord(exercise).insert(db)
        }
        let dayStart = Calendar.current.startOfDay(for: DatabaseFixtures.referenceDate)
        return Context(database: database, exercise: exercise, dayStart: dayStart, now: dayStart.addingTimeInterval(secondsPerDay * 2))
    }

    private static func log(_ context: Context, startedAt: Date, setCount: Int) async throws -> UUID {
        let workout = Workout(
            id: UUID(),
            programDay: nil,
            startedAt: startedAt,
            finishedAt: startedAt.addingTimeInterval(secondsPerHour),
            note: nil,
            rest: nil
        )
        let item = DatabaseFixtures.makeWorkoutExercise(workoutId: workout.id, exerciseId: context.exercise.id)
        try await context.database.writer.write { db in
            try WorkoutRecord(workout).insert(db)
            try WorkoutExerciseRecord(item).insert(db)
            for position in 0..<setCount {
                let entry = SetEntry(
                    id: UUID(),
                    workoutExerciseId: item.id,
                    position: position,
                    weight: .zero,
                    reps: 10,
                    durationSeconds: nil,
                    isWarmup: false,
                    startedAt: nil,
                    completedAt: startedAt.addingTimeInterval(TimeInterval(position))
                )
                try SetEntryRecord(entry).insert(db)
            }
        }
        return workout.id
    }

    private static func waitFor(_ condition: () -> Bool) async throws {
        for _ in 0..<pollAttempts {
            if condition() {
                return
            }
            try await Task.sleep(for: pollInterval)
        }
        throw WorkoutError.notFound
    }

    @Test func dayTapOpensTheOnlyWorkoutOrTheDayWithSeveral() async throws {
        let context = try await Self.makeContext()
        let morning = context.dayStart.addingTimeInterval(Self.secondsPerHour * 9)
        _ = try await Self.log(context, startedAt: morning, setCount: 3)
        _ = try await Self.log(context, startedAt: morning.addingTimeInterval(Self.secondsPerHour * 6), setCount: 2)
        let nextDay = context.dayStart.addingTimeInterval(Self.secondsPerDay)
        let single = try await Self.log(context, startedAt: nextDay.addingTimeInterval(Self.secondsPerHour * 9), setCount: 4)
        let now = context.now
        let viewModel = HistoryViewModel(
            observeHistory: ObserveHistoryUseCase(repository: WorkoutRepositoryImpl(database: context.database), now: { return now }),
            now: { return now }
        )
        let task = Task {
            await viewModel.observe()
        }
        defer {
            task.cancel()
        }

        try await Self.waitFor {
            guard case let .success(data) = viewModel.historyUiState else {
                return false
            }
            return data.sections.flatMap(\.items).count == 3
        }

        #expect(viewModel.target(forDay: context.dayStart) == .day(date: context.dayStart))
        #expect(viewModel.target(forDay: nextDay) == .workout(id: single))
        #expect(viewModel.target(forDay: now) == nil)
    }

    @Test func deletingTheWorkoutMovesDetailsToDeleted() async throws {
        let context = try await Self.makeContext()
        let workoutId = try await Self.log(context, startedAt: context.dayStart.addingTimeInterval(Self.secondsPerHour * 9), setCount: 2)
        let repository = WorkoutRepositoryImpl(database: context.database)
        let viewModel = WorkoutDetailsViewModel(
            observeFinishedWorkout: ObserveFinishedWorkoutUseCase(repository: repository),
            deleteWorkout: DeleteWorkoutUseCase(repository: repository),
            workoutId: workoutId
        )
        let task = Task {
            await viewModel.observe()
        }
        defer {
            task.cancel()
        }

        try await Self.waitFor {
            guard case let .success(data) = viewModel.workoutDetailsUiState else {
                return false
            }
            return data.setCountValue == 2.formatted()
        }
        await viewModel.delete()
        try await Self.waitFor {
            guard case .deleted = viewModel.workoutDetailsUiState else {
                return false
            }
            return true
        }
    }
}
