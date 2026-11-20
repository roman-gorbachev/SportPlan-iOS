import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct AddExerciseViewModelTests {
    private static let pollInterval = Duration.milliseconds(10)
    private static let pollAttempts = 300
    private static let maximumRestSeconds = 600
    private static let restStepSeconds = 15

    private static func makeViewModel(
        target: AddExerciseTarget,
        database: AppDatabase,
        dayContext: AddExerciseDayContext? = nil
    ) -> AddExerciseViewModel {
        let equipmentRepository = EquipmentRepositoryImpl(database: database)
        let exerciseRepository = ExerciseRepositoryImpl(database: database)
        return AddExerciseViewModel(
            target: target,
            dayContext: dayContext,
            observeEquipmentChoices: ObserveEquipmentChoicesUseCase(repository: equipmentRepository),
            createExercise: CreateExerciseUseCase(
                exerciseRepository: exerciseRepository,
                equipmentRepository: equipmentRepository,
                now: { return DatabaseFixtures.referenceDate }
            ),
            addExerciseToDay: AddExerciseToDayUseCase(
                programRepository: ProgramRepositoryImpl(database: database),
                exerciseRepository: exerciseRepository
            )
        )
    }

    private static func data(of viewModel: AddExerciseViewModel) throws -> AddExerciseUiData {
        guard case let .success(data) = viewModel.addExerciseUiState else {
            throw ExerciseError.notFound
        }
        return data
    }

    private static func insert(_ equipment: [Equipment], into database: AppDatabase) async throws {
        try await database.writer.write { db in
            for item in equipment {
                try EquipmentRecord(item).insert(db)
            }
        }
    }

    private static func makeEquipment(name: String, kind: EquipmentKind) -> Equipment {
        var equipment = DatabaseFixtures.makeEquipment()
        equipment.name = name
        equipment.kind = kind
        return equipment
    }

    private static func observeUntil(
        _ viewModel: AddExerciseViewModel,
        condition: (AddExerciseUiData) -> Bool
    ) async throws -> AddExerciseUiData {
        let observation = Task {
            await viewModel.observeEquipment()
        }
        defer {
            observation.cancel()
        }
        for _ in 0..<pollAttempts {
            let data = try Self.data(of: viewModel)
            if condition(data) {
                return data
            }
            try await Task.sleep(for: pollInterval)
        }
        return try Self.data(of: viewModel)
    }

    @Test func singleMatchingEquipmentIsSelectedAutomatically() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let barbell = Self.makeEquipment(name: "Олимпийский гриф", kind: .barbell)
        try await Self.insert([barbell, Self.makeEquipment(name: "Гантели", kind: .dumbbell)], into: database)
        let viewModel = Self.makeViewModel(target: .quick(.benchPress), database: database)

        let data = try await Self.observeUntil(viewModel) { data in
            return !data.equipmentChoices.isEmpty
        }

        #expect(data.equipmentChoices.map(\.id) == [barbell.id])
        #expect(data.equipmentChoices.first?.isSelected == true)
        #expect(data.canSave)
    }

    @Test func severalMatchingEquipmentLeaveSelectionEmpty() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let olympic = Self.makeEquipment(name: "Олимпийский гриф", kind: .barbell)
        try await Self.insert([olympic, Self.makeEquipment(name: "EZ-гриф", kind: .barbell)], into: database)
        let viewModel = Self.makeViewModel(target: .blank, database: database)
        viewModel.selectLoadKind(.equipment(.barbell))
        viewModel.updateName("Штанга")

        let data = try await Self.observeUntil(viewModel) { data in
            return data.equipmentChoices.count == 2
        }

        #expect(data.equipmentChoices.allSatisfy { item in
            return !item.isSelected
        })
        #expect(data.canSave == false)

        viewModel.selectEquipment(id: olympic.id)
        #expect(try Self.data(of: viewModel).canSave)
    }

    @Test func createdEquipmentBecomesSelected() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let viewModel = Self.makeViewModel(target: .quick(.squat), database: database)
        #expect(try Self.data(of: viewModel).canSave == false)

        let created = Self.makeEquipment(name: "Новый гриф", kind: .barbell)
        try await Self.insert([created], into: database)
        viewModel.selectCreatedEquipment(created)

        let data = try Self.data(of: viewModel)
        #expect(data.equipmentChoices.first(where: \.isSelected)?.id == created.id)
        #expect(data.canSave)
    }

    @Test func createdEquipmentOfAnotherKindIsIgnored() throws {
        let viewModel = Self.makeViewModel(target: .quick(.squat), database: try DatabaseFixtures.makeDatabase())

        viewModel.selectCreatedEquipment(Self.makeEquipment(name: "Гантели", kind: .dumbbell))

        #expect(try Self.data(of: viewModel).equipmentChoices.isEmpty)
    }

    @Test func quickExerciseFillsTheDraft() throws {
        let viewModel = Self.makeViewModel(target: .quick(.plank), database: try DatabaseFixtures.makeDatabase())

        let data = try Self.data(of: viewModel)
        #expect(viewModel.startsAtDetails)
        #expect(data.name == QuickExercise.plank.title)
        #expect(data.loadKind == .bodyweight)
        #expect(data.metric == .duration)
        #expect(data.showsMetricPicker)
        #expect(data.canSave)
    }

    @Test func changingKindResetsEquipmentAndMetric() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let barbell = Self.makeEquipment(name: "Олимпийский гриф", kind: .barbell)
        try await Self.insert([barbell], into: database)
        let viewModel = Self.makeViewModel(target: .blank, database: database)
        viewModel.selectLoadKind(.bodyweight)
        viewModel.updateMetric(.duration)
        #expect(try Self.data(of: viewModel).metric == .duration)

        viewModel.selectLoadKind(.equipment(.barbell))
        _ = try await Self.observeUntil(viewModel) { data in
            return data.equipmentChoices.contains(where: \.isSelected)
        }
        viewModel.selectLoadKind(.equipment(.dumbbell))

        let data = try Self.data(of: viewModel)
        #expect(viewModel.startsAtDetails == false)
        #expect(data.metric == .weightReps)
        #expect(data.showsMetricPicker == false)
        #expect(data.equipmentChoices.isEmpty)
        #expect(data.canSave == false)
    }

    @Test func durationIsRejectedForEquipmentKinds() throws {
        let viewModel = Self.makeViewModel(target: .quick(.benchPress), database: try DatabaseFixtures.makeDatabase())

        viewModel.updateMetric(.duration)

        #expect(try Self.data(of: viewModel).metric == .weightReps)
    }

    @Test func restStepperStopsAtBounds() throws {
        let viewModel = Self.makeViewModel(target: .quick(.pullUp), database: try DatabaseFixtures.makeDatabase())
        #expect(try Self.data(of: viewModel).restText == "1:30")

        for _ in 0..<(Self.maximumRestSeconds / Self.restStepSeconds) {
            viewModel.incrementRest()
        }
        var data = try Self.data(of: viewModel)
        #expect(data.restText == "10:00")
        #expect(data.canIncrementRest == false)

        for _ in 0..<(Self.maximumRestSeconds / Self.restStepSeconds) {
            viewModel.decrementRest()
        }
        data = try Self.data(of: viewModel)
        #expect(data.restText == "0:00")
        #expect(data.canDecrementRest == false)
        #expect(data.canIncrementRest)
    }

    @Test func savingCreatesTheExercise() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let viewModel = Self.makeViewModel(target: .quick(.dip), database: database)
        viewModel.updateDescription("  ")

        let saved = await viewModel.save()

        let exercises = try await database.reader.read { db in
            return try ExerciseRecord.fetchAll(db).map { record in
                return try record.toDomainModel()
            }
        }
        #expect(saved?.name == QuickExercise.dip.title)
        #expect(exercises.map(\.name) == [QuickExercise.dip.title])
        #expect(exercises.first?.load == .bodyweight)
        #expect(exercises.first?.description == nil)
    }

    @Test func emptyNameDisablesSave() throws {
        let viewModel = Self.makeViewModel(target: .quick(.pullUp), database: try DatabaseFixtures.makeDatabase())

        viewModel.updateName("   ")

        #expect(try Self.data(of: viewModel).canSave == false)
    }

    @Test func savingInDayContextPutsExerciseIntoDay() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        _ = try await ProgramRepositoryImpl(database: database).createProgram(program, firstDay: day)
        let context = AddExerciseDayContext(dayId: day.id, title: "A · Грудь и трицепс")
        let viewModel = Self.makeViewModel(target: .quick(.plank), database: database, dayContext: context)
        viewModel.stepDayTargets(.incrementSets)

        let data = try Self.data(of: viewModel)
        #expect(data.dayTargets?.showsReps == false)
        #expect(await viewModel.save() != nil)

        let planned = try await database.reader.read { db in
            return try PlannedExerciseRecord.fetchAll(db).map { record in
                return try record.toDomainModel()
            }
        }
        #expect(planned.count == 1)
        #expect(planned.first?.programDayId == day.id)
        #expect(planned.first?.targetSets == 4)
        #expect(planned.first?.targetReps == nil)
    }
}
