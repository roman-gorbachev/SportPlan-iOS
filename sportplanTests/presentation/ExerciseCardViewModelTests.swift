import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct ExerciseCardViewModelTests {
    private static let pollInterval = Duration.milliseconds(10)
    private static let pollAttempts = 300
    private static let secondsPerWeek: TimeInterval = 604_800

    private struct LoggedSet {
        let kilograms: Double
        let reps: Int?
        let durationSeconds: Int?
    }

    private static func makeExercise(_ database: AppDatabase, load: ExerciseLoad, metric: ExerciseMetric = .weightReps) async throws -> Exercise {
        var exercise = DatabaseFixtures.makeExercise(load: load)
        exercise.metric = metric
        let stored = exercise
        try await database.writer.write { db in
            try ExerciseRecord(stored).insert(db)
        }
        return stored
    }

    private static func log(_ database: AppDatabase, exercise: Exercise, week: Int, sets: [LoggedSet]) async throws {
        let startedAt = DatabaseFixtures.referenceDate.addingTimeInterval(TimeInterval(week) * secondsPerWeek)
        let workout = Workout(id: UUID(), programDay: nil, startedAt: startedAt, finishedAt: startedAt, note: nil, rest: nil)
        let item = DatabaseFixtures.makeWorkoutExercise(workoutId: workout.id, exerciseId: exercise.id)
        try await database.writer.write { db in
            try WorkoutRecord(workout).insert(db)
            try WorkoutExerciseRecord(item).insert(db)
            for (position, logged) in sets.enumerated() {
                let entry = SetEntry(
                    id: UUID(),
                    workoutExerciseId: item.id,
                    position: position,
                    weight: Weight(kilograms: logged.kilograms),
                    reps: logged.reps,
                    durationSeconds: logged.durationSeconds,
                    isWarmup: false,
                    startedAt: nil,
                    completedAt: startedAt.addingTimeInterval(TimeInterval(position))
                )
                try SetEntryRecord(entry).insert(db)
            }
        }
    }

    private static func waitForData(
        _ viewModel: ExerciseCardViewModel,
        condition: (ExerciseCardUiData) -> Bool = { _ in return true }
    ) async throws -> ExerciseCardUiData {
        for _ in 0..<pollAttempts {
            if case let .success(data) = viewModel.exerciseCardUiState, condition(data) {
                return data
            }
            try await Task.sleep(for: pollInterval)
        }
        throw ExerciseError.notFound
    }

    private static func observe(_ viewModel: ExerciseCardViewModel) -> Task<Void, Never> {
        return Task {
            await viewModel.observe()
        }
    }

    private static func makeViewModel(_ database: AppDatabase, exerciseId: UUID) -> ExerciseCardViewModel {
        let useCase = ObserveExerciseCardUseCase(repository: WorkoutRepositoryImpl(database: database))
        return ExerciseCardViewModel(observeExerciseCard: useCase, exerciseId: exerciseId)
    }

    @Test func exerciseWithoutHistoryShowsTheEmptyCard() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let exercise = try await Self.makeExercise(database, load: .bodyweight)
        let viewModel = Self.makeViewModel(database, exerciseId: exercise.id)
        let task = Self.observe(viewModel)
        defer {
            task.cancel()
        }

        let data = try await Self.waitForData(viewModel)

        #expect(data.hasData == false)
        #expect(data.chart.value == String(localized: "workout.set.noValue"))
        #expect(data.chartPlaceholder == String(localized: "exerciseCard.empty"))
        #expect(data.records.isEmpty)
        #expect(data.showsMetricPicker == false)
    }

    @Test func weightedCardShowsRecordsAndSwitchesTheMetric() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let bar = DatabaseFixtures.makeEquipment()
        try await database.writer.write { db in
            try EquipmentRecord(bar).insert(db)
        }
        let bench = try await Self.makeExercise(database, load: .equipment(id: bar.id))
        try await Self.log(database, exercise: bench, week: 0, sets: [LoggedSet(kilograms: 60, reps: 8, durationSeconds: nil)])
        try await Self.log(database, exercise: bench, week: 1, sets: [
            LoggedSet(kilograms: 65, reps: 8, durationSeconds: nil),
            LoggedSet(kilograms: 62.5, reps: 9, durationSeconds: nil),
        ])
        let viewModel = Self.makeViewModel(database, exerciseId: bench.id)
        let task = Self.observe(viewModel)
        defer {
            task.cancel()
        }

        let data = try await Self.waitForData(viewModel)

        #expect(data.showsMetricPicker)
        #expect(data.chart.value == "82,3")
        #expect(data.chart.delta == String(localized: "exerciseCard.delta.up \("6,3")"))
        #expect(data.records.map(\.title) == [
            String(localized: "exerciseCard.metric.maxWeight"),
            String(localized: "exerciseCard.metric.oneRepMax"),
        ])
        #expect(data.records.map(\.caption).last == String(localized: "exerciseCard.record.epley"))
        #expect(data.sessions.map(\.isRecord) == [true, false])

        viewModel.selectMetric(.maxWeight)
        let switched = try await Self.waitForData(viewModel) { data in
            return data.selectedMetric == .maxWeight
        }
        #expect(switched.chart.value == "65")
        #expect(switched.chart.delta == String(localized: "exerciseCard.delta.up \("5")"))
    }

    @Test func bodyweightAndTimedCardsUseTheirOwnRecords() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let pullUps = try await Self.makeExercise(database, load: .bodyweight)
        try await Self.log(database, exercise: pullUps, week: 0, sets: [
            LoggedSet(kilograms: 0, reps: 14, durationSeconds: nil),
            LoggedSet(kilograms: 15, reps: 6, durationSeconds: nil),
        ])
        let plank = try await Self.makeExercise(database, load: .bodyweight, metric: .duration)
        try await Self.log(database, exercise: plank, week: 0, sets: [LoggedSet(kilograms: 0, reps: nil, durationSeconds: 130)])

        let pullUpsModel = Self.makeViewModel(database, exerciseId: pullUps.id)
        let plankModel = Self.makeViewModel(database, exerciseId: plank.id)
        let tasks = [Self.observe(pullUpsModel), Self.observe(plankModel)]
        defer {
            tasks.forEach { task in task.cancel() }
        }

        let pullUpsData = try await Self.waitForData(pullUpsModel)
        #expect(pullUpsData.records.map(\.title) == [
            String(localized: "exerciseCard.metric.maxReps"),
            String(localized: "exerciseCard.record.maxWeighted"),
        ])
        #expect(pullUpsData.records.first?.value == "14")
        #expect(pullUpsData.chart.unit == String(localized: "exerciseCard.unit.reps"))

        let plankData = try await Self.waitForData(plankModel)
        #expect(plankData.records.map(\.value) == ["2:10"])
        #expect(plankData.chart.value == "2:10")
        #expect(plankData.chart.delta == nil)
    }
}
