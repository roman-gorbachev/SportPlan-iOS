import Domain
import Foundation
import Testing

struct ExerciseLibraryTests {
    private static func makeItem(_ name: String, equipment: Equipment?) -> LibraryExercise {
        let load: ExerciseLoad = equipment.map { item in
            return ExerciseLoad.equipment(id: item.id)
        } ?? .bodyweight
        return LibraryExercise(exercise: DomainFixtures.makeExercise(name: name, load: load), equipment: equipment)
    }

    @Test func groupsByCategoryAndSortsByName() {
        let bar = DomainFixtures.makeEquipment()
        let dumbbells = DomainFixtures.makeEquipment(name: "Гантели", kind: .dumbbell)
        let crossover = DomainFixtures.makeEquipment(name: "Кроссовер", kind: .selectorizedMachine)
        let library = ExerciseLibrary(exercises: [
            Self.makeItem("Планка", equipment: nil),
            Self.makeItem("Присед", equipment: bar),
            Self.makeItem("Разгибания на блоке", equipment: crossover),
            Self.makeItem("Жим гантелей", equipment: dumbbells),
            Self.makeItem("Брусья", equipment: nil),
        ])
        #expect(library.sections.map(\.category) == [.freeWeight, .machine, .bodyweight])
        #expect(library.sections[0].exercises.map(\.exercise.name) == ["Жим гантелей", "Присед"])
        #expect(library.sections[2].exercises.map(\.exercise.name) == ["Брусья", "Планка"])
        #expect(library.count == 5)
    }

    @Test func omitsEmptyCategories() {
        let library = ExerciseLibrary(exercises: [Self.makeItem("Брусья", equipment: nil)])
        #expect(library.sections.map(\.category) == [.bodyweight])
        #expect(ExerciseLibrary(exercises: []).isEmpty)
    }

    @Test func filtersIgnoringCaseAndDiacritics() {
        let library = ExerciseLibrary(exercises: [
            Self.makeItem("Жим лёжа", equipment: DomainFixtures.makeEquipment()),
            Self.makeItem("Подтягивания", equipment: nil),
        ])
        #expect(library.filtered(by: "ЛЕЖА").count == 1)
        #expect(library.filtered(by: "  ").count == 2)
        #expect(library.filtered(by: "присед").isEmpty)
    }

    @Test func observeUseCaseBuildsLibrary() async throws {
        let repository = FakeExerciseRepository(library: [Self.makeItem("Брусья", equipment: nil)])
        var iterator = ObserveExerciseLibraryUseCase(repository: repository).execute().makeAsyncIterator()
        let library = try await iterator.next()
        #expect(library?.count == 1)
    }

    @Test func equipmentChoicesFilterByKind() async throws {
        let bar = DomainFixtures.makeEquipment()
        let repository = FakeEquipmentRepository(equipment: [bar, DomainFixtures.makeEquipment(name: "Гантели", kind: .dumbbell)])
        var iterator = ObserveEquipmentChoicesUseCase(repository: repository).execute(kind: .barbell).makeAsyncIterator()
        let choices = try await iterator.next()
        #expect(choices == [bar])
    }
}
