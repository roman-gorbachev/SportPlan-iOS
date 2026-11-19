import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct ProgramsViewModelTests {
    private static let pollInterval = Duration.milliseconds(10)
    private static let pollAttempts = 300

    private struct ProgramsFixture {
        let database: AppDatabase
        let program: Program
        let firstDay: ProgramDay
        let secondDay: ProgramDay
    }

    private static func makeFixture() async throws -> ProgramsFixture {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ProgramRepositoryImpl(database: database)
        let program = DatabaseFixtures.makeProgram()
        let firstDay = DatabaseFixtures.makeDay(programId: program.id)
        _ = try await repository.createProgram(program, firstDay: firstDay)
        var secondDay = DatabaseFixtures.makeDay(programId: program.id)
        secondDay.name = "Спина и бицепс"
        secondDay.label = "B"
        secondDay.position = 1
        _ = try await repository.addDay(secondDay)
        return ProgramsFixture(database: database, program: program, firstDay: firstDay, secondDay: secondDay)
    }

    private static func makeViewModel(database: AppDatabase) -> ProgramsViewModel {
        let programs = ProgramRepositoryImpl(database: database)
        return ProgramsViewModel(
            observeExerciseLibrary: ObserveExerciseLibraryUseCase(repository: ExerciseRepositoryImpl(database: database)),
            observePrograms: ObserveProgramsUseCase(repository: programs),
            deleteProgram: DeleteProgramUseCase(repository: programs),
            deleteProgramDay: DeleteProgramDayUseCase(repository: programs)
        )
    }

    private static func dataUntil(
        _ viewModel: ProgramsViewModel,
        condition: (ProgramsUiData) -> Bool
    ) async throws -> ProgramsUiData? {
        for _ in 0..<pollAttempts {
            if case let .success(data) = viewModel.programsUiState, condition(data) {
                return data
            }
            try await Task.sleep(for: pollInterval)
        }
        return nil
    }

    private static func dayIds(_ data: ProgramsUiData) -> [UUID] {
        return data.programs.flatMap(\.days).map(\.id)
    }

    @Test func deletingADayAsksFirstAndRemovesOnlyThatDay() async throws {
        let fixture = try await Self.makeFixture()
        let viewModel = Self.makeViewModel(database: fixture.database)
        let libraryTask = Task {
            await viewModel.observeLibrary()
        }
        let programsTask = Task {
            await viewModel.observeProgramList()
        }
        defer {
            libraryTask.cancel()
            programsTask.cancel()
        }
        _ = try #require(try await Self.dataUntil(viewModel) { data in
            return Self.dayIds(data).count == 2
        })

        viewModel.requestDeleteDay(id: fixture.secondDay.id)
        let asking = try #require(try await Self.dataUntil(viewModel) { data in
            return data.pendingDayDeletion != nil
        })
        #expect(asking.pendingDayDeletion?.dayName == "Спина и бицепс")

        await viewModel.confirmDeleteDay(id: fixture.secondDay.id)
        let updated = try await Self.dataUntil(viewModel) { data in
            return Self.dayIds(data) == [fixture.firstDay.id] && data.pendingDayDeletion == nil
        }
        #expect(updated != nil)
    }

    @Test func cancellingDayDeletionKeepsTheDay() async throws {
        let fixture = try await Self.makeFixture()
        let viewModel = Self.makeViewModel(database: fixture.database)
        let libraryTask = Task {
            await viewModel.observeLibrary()
        }
        let programsTask = Task {
            await viewModel.observeProgramList()
        }
        defer {
            libraryTask.cancel()
            programsTask.cancel()
        }
        _ = try #require(try await Self.dataUntil(viewModel) { data in
            return Self.dayIds(data).count == 2
        })

        viewModel.requestDeleteDay(id: fixture.firstDay.id)
        viewModel.cancelDeleteDay()
        let data = try #require(try await Self.dataUntil(viewModel) { data in
            return data.pendingDayDeletion == nil
        })
        #expect(Self.dayIds(data).count == 2)
        let storedDays = try await fixture.database.reader.read { db in
            return try ProgramDayRecord.fetchCount(db)
        }
        #expect(storedDays == 2)
    }
}
