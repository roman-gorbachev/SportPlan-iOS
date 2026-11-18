import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct ProgramFormsViewModelTests {
    private static func makeProgramForm(target: ProgramFormTarget, database: AppDatabase) -> ProgramFormViewModel {
        let repository = ProgramRepositoryImpl(database: database)
        return ProgramFormViewModel(
            target: target,
            createProgram: CreateProgramUseCase(repository: repository, now: { return DatabaseFixtures.referenceDate }),
            renameProgram: RenameProgramUseCase(repository: repository)
        )
    }

    private static func makeDayForm(target: ProgramDayFormTarget, database: AppDatabase) -> ProgramDayFormViewModel {
        let repository = ProgramRepositoryImpl(database: database)
        return ProgramDayFormViewModel(
            target: target,
            addProgramDay: AddProgramDayUseCase(repository: repository),
            updateProgramDay: UpdateProgramDayUseCase(repository: repository),
            deleteProgramDay: DeleteProgramDayUseCase(repository: repository)
        )
    }

    private static func programFormData(_ viewModel: ProgramFormViewModel) throws -> ProgramFormUiData {
        guard case let .success(data) = viewModel.programFormUiState else {
            throw ProgramError.notFound
        }
        return data
    }

    private static func dayFormData(_ viewModel: ProgramDayFormViewModel) throws -> ProgramDayFormUiData {
        guard case let .success(data) = viewModel.dayFormUiState else {
            throw ProgramError.notFound
        }
        return data
    }

    @Test func creatingNeedsProgramAndFirstDayNames() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let viewModel = Self.makeProgramForm(target: .create, database: database)
        viewModel.updateName("Сила 3×")
        #expect(try Self.programFormData(viewModel).canSave == false)

        viewModel.updateDayLabel("A")
        viewModel.updateDayName("Грудь и трицепс")
        #expect(try Self.programFormData(viewModel).canSave)
        #expect(await viewModel.save())

        let days = try await database.reader.read { db in
            return try ProgramDayRecord.fetchAll(db)
        }
        #expect(days.map(\.name) == ["Грудь и трицепс"])
        #expect(days.first?.label == "A")
    }

    @Test func renamingNeedsOnlyTheName() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let program = DatabaseFixtures.makeProgram()
        _ = try await ProgramRepositoryImpl(database: database).createProgram(program, firstDay: DatabaseFixtures.makeDay(programId: program.id))
        let viewModel = Self.makeProgramForm(target: .rename(id: program.id, name: program.name), database: database)
        #expect(try Self.programFormData(viewModel).isCreating == false)
        #expect(try Self.programFormData(viewModel).canSave)

        viewModel.updateName("Сила 4×")
        #expect(await viewModel.save())
        let stored = try await database.reader.read { db in
            return try ProgramRecord.fetchOne(db)?.name
        }
        #expect(stored == "Сила 4×")
    }

    @Test func longDayLabelDisablesSave() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let viewModel = Self.makeDayForm(target: .new(programId: UUID(), programName: "Сила 3×"), database: database)
        viewModel.updateName("Спина и бицепс")
        viewModel.updateLabel("B")
        #expect(try Self.dayFormData(viewModel).canSave)

        viewModel.updateLabel("Спина")
        #expect(try Self.dayFormData(viewModel).canSave == false)
    }

    @Test func deletingDayRemovesIt() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        _ = try await ProgramRepositoryImpl(database: database).createProgram(program, firstDay: day)
        let viewModel = Self.makeDayForm(target: .edit(day: day, programName: program.name), database: database)

        viewModel.requestDelete()
        #expect(try Self.dayFormData(viewModel).isConfirmingDelete)
        #expect(await viewModel.confirmDelete())
        let count = try await database.reader.read { db in
            return try ProgramDayRecord.fetchCount(db)
        }
        #expect(count == 0)
    }
}
