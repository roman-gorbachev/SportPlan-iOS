import Domain
import Foundation
import Testing

struct CreateProgramUseCaseTests {
    @Test func createsProgramWithFirstDay() async throws {
        let repository = FakeProgramRepository()
        let useCase = CreateProgramUseCase(repository: repository, now: { return DomainFixtures.referenceDate })
        let program = try await useCase.execute(
            program: ProgramDraft(name: " Сила 3× "),
            firstDay: ProgramDayDraft(name: " Грудь и трицепс ", label: " A ")
        )
        #expect(program.name == "Сила 3×")
        #expect(program.createdAt == DomainFixtures.referenceDate)
        #expect(repository.programs == [program])
        let day = try #require(repository.days.first)
        #expect(day.programId == program.id)
        #expect(day.name == "Грудь и трицепс")
        #expect(day.label == "A")
    }

    @Test func rejectsInvalidProgramOrDay() async throws {
        let repository = FakeProgramRepository()
        let useCase = CreateProgramUseCase(repository: repository, now: { return DomainFixtures.referenceDate })
        await #expect(throws: ProgramError.invalidDraft([.emptyName, .labelTooLong])) {
            _ = try await useCase.execute(program: ProgramDraft(name: " "), firstDay: ProgramDayDraft(name: "День", label: "Длинная"))
        }
        #expect(repository.programs.isEmpty)
        #expect(repository.days.isEmpty)
    }
}
