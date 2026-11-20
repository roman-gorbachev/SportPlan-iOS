import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct SettingsViewModelTests {
    private static let pollInterval = Duration.milliseconds(10)
    private static let pollAttempts = 300

    private struct Context {
        let database: AppDatabase
        let viewModel: SettingsViewModel
        let store: ActiveWorkoutStore
    }

    private static func makeContext(database: AppDatabase) -> Context {
        let workouts = WorkoutRepositoryImpl(database: database)
        let backups = BackupRepositoryImpl(database: database)
        let store = ActiveWorkoutStore(observeActiveWorkout: ObserveActiveWorkoutUseCase(repository: workouts))
        let viewModel = SettingsViewModel(
            observeGymEquipment: ObserveGymEquipmentUseCase(repository: EquipmentRepositoryImpl(database: database)),
            observePlates: ObservePlatesUseCase(repository: PlateRepositoryImpl(database: database)),
            exportBackup: ExportBackupUseCase(repository: backups, now: { return DatabaseFixtures.referenceDate }),
            readBackup: ReadBackupUseCase(repository: backups),
            importBackup: ImportBackupUseCase(backupRepository: backups, workoutRepository: workouts),
            workoutStore: store,
            appVersion: "1.0"
        )
        return Context(database: database, viewModel: viewModel, store: store)
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

    private static func data(_ viewModel: SettingsViewModel) -> SettingsUiData? {
        guard case let .success(data) = viewModel.settingsUiState else {
            return nil
        }
        return data
    }

    private static func exportFile(equipmentCount: Int) async throws -> URL {
        let database = try DatabaseFixtures.makeDatabase()
        try await database.writer.write { db in
            for _ in 0..<equipmentCount {
                try EquipmentRecord(DatabaseFixtures.makeEquipment()).insert(db)
            }
        }
        let contents = try await BackupRepositoryImpl(database: database).makeBackup(exportedAt: DatabaseFixtures.referenceDate)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        try contents.write(to: url)
        return url
    }

    private static func start(_ context: Context) -> [Task<Void, Never>] {
        let viewModel = context.viewModel
        let store = context.store
        return [
            Task {
                await store.observe()
            },
            Task {
                await viewModel.observe()
            },
        ]
    }

    @Test func readConfirmAndImportReplacesTheData() async throws {
        let context = Self.makeContext(database: try DatabaseFixtures.makeDatabase())
        let tasks = Self.start(context)
        defer {
            tasks.forEach { task in
                task.cancel()
            }
        }
        let viewModel = context.viewModel
        try await Self.waitFor { return Self.data(viewModel)?.isImportAvailable == true }
        #expect(Self.data(viewModel)?.equipmentCount == 0)

        await viewModel.readImport(fileURL: try await Self.exportFile(equipmentCount: 2))
        guard case let .confirming(message) = Self.data(viewModel)?.importStep else {
            Issue.record("Expected the confirmation step")
            return
        }
        let summary = BackupSummary(exportedAt: DatabaseFixtures.referenceDate, workoutCount: 0, exerciseCount: 0, programCount: 0)
        #expect(message == SettingsFormatting.importMessage(summary))
        #expect(Self.data(viewModel)?.equipmentCount == 0)

        viewModel.confirmImport()
        try await Self.waitFor { return Self.data(viewModel)?.importStep == .finished }
        try await Self.waitFor { return Self.data(viewModel)?.equipmentCount == 2 }
        #expect(viewModel.dismissImportResult())
        #expect(Self.data(viewModel)?.importStep == .idle)
    }

    @Test func cancelKeepsTheData() async throws {
        let context = Self.makeContext(database: try DatabaseFixtures.makeDatabase())
        let tasks = Self.start(context)
        defer {
            tasks.forEach { task in
                task.cancel()
            }
        }
        let viewModel = context.viewModel
        try await Self.waitFor { return Self.data(viewModel)?.isImportAvailable == true }
        await viewModel.readImport(fileURL: try await Self.exportFile(equipmentCount: 1))
        viewModel.cancelImport()
        #expect(Self.data(viewModel)?.importStep == .idle)
        viewModel.confirmImport()
        #expect(Self.data(viewModel)?.importStep == .idle)
        let equipmentCount = try await context.database.reader.read { db in
            return try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM equipment") ?? 0
        }
        #expect(equipmentCount == 0)
        #expect(!viewModel.dismissImportResult())
    }

    @Test func unreadableFileShowsTheFailure() async throws {
        let context = Self.makeContext(database: try DatabaseFixtures.makeDatabase())
        let tasks = Self.start(context)
        defer {
            tasks.forEach { task in
                task.cancel()
            }
        }
        let viewModel = context.viewModel
        try await Self.waitFor { return Self.data(viewModel) != nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        try Data("[]".utf8).write(to: url)
        await viewModel.readImport(fileURL: url)
        #expect(Self.data(viewModel)?.importStep == .failed(message: String(localized: "settings.data.error.unreadable")))
    }

    @Test func importIsUnavailableDuringAWorkout() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        try await StartEmptyWorkoutUseCase(repository: WorkoutRepositoryImpl(database: database), now: { return Date() }).execute()
        let context = Self.makeContext(database: database)
        let tasks = Self.start(context)
        defer {
            tasks.forEach { task in
                task.cancel()
            }
        }
        let viewModel = context.viewModel
        try await Self.waitFor {
            guard case .active = context.store.state else {
                return false
            }
            return Self.data(viewModel) != nil
        }
        #expect(Self.data(viewModel)?.isImportAvailable == false)
    }
}
