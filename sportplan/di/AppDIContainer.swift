import Domain
import Foundation

final class AppDIContainer {
    private static let appVersionKey = "CFBundleShortVersionString"

    private let appDatabase: AppDatabase

    private lazy var equipmentRepository: any EquipmentRepository = EquipmentRepositoryImpl(database: appDatabase)
    private lazy var exerciseRepository: any ExerciseRepository = ExerciseRepositoryImpl(database: appDatabase)
    private lazy var programRepository: any ProgramRepository = ProgramRepositoryImpl(database: appDatabase)

    private lazy var observeGymEquipmentUseCase = ObserveGymEquipmentUseCase(repository: equipmentRepository)
    private lazy var loadEquipmentEditorUseCase = LoadEquipmentEditorUseCase(repository: equipmentRepository)
    private lazy var saveEquipmentUseCase = SaveEquipmentUseCase(repository: equipmentRepository, now: { return Date() })
    private lazy var archiveEquipmentUseCase = ArchiveEquipmentUseCase(repository: equipmentRepository)

    private lazy var observeExerciseLibraryUseCase = ObserveExerciseLibraryUseCase(repository: exerciseRepository)
    private lazy var observeEquipmentChoicesUseCase = ObserveEquipmentChoicesUseCase(repository: equipmentRepository)
    private lazy var createExerciseUseCase = CreateExerciseUseCase(
        exerciseRepository: exerciseRepository,
        equipmentRepository: equipmentRepository,
        now: { return Date() }
    )
    private lazy var countProgramDaysUsingExerciseUseCase = CountProgramDaysUsingExerciseUseCase(repository: exerciseRepository)
    private lazy var archiveExerciseUseCase = ArchiveExerciseUseCase(repository: exerciseRepository)

    private lazy var observeProgramsUseCase = ObserveProgramsUseCase(repository: programRepository)
    private lazy var observeProgramDayUseCase = ObserveProgramDayUseCase(repository: programRepository)
    private lazy var createProgramUseCase = CreateProgramUseCase(repository: programRepository, now: { return Date() })
    private lazy var renameProgramUseCase = RenameProgramUseCase(repository: programRepository)
    private lazy var deleteProgramUseCase = DeleteProgramUseCase(repository: programRepository)
    private lazy var addProgramDayUseCase = AddProgramDayUseCase(repository: programRepository)
    private lazy var updateProgramDayUseCase = UpdateProgramDayUseCase(repository: programRepository)
    private lazy var deleteProgramDayUseCase = DeleteProgramDayUseCase(repository: programRepository)
    private lazy var addExerciseToDayUseCase = AddExerciseToDayUseCase(
        programRepository: programRepository,
        exerciseRepository: exerciseRepository
    )
    private lazy var updatePlannedExerciseTargetsUseCase = UpdatePlannedExerciseTargetsUseCase(
        programRepository: programRepository,
        exerciseRepository: exerciseRepository
    )
    private lazy var removePlannedExerciseUseCase = RemovePlannedExerciseUseCase(repository: programRepository)
    private lazy var reorderPlannedExercisesUseCase = ReorderPlannedExercisesUseCase(repository: programRepository)

    init() {
        do {
            appDatabase = try AppDatabase.makePersistent()
        } catch {
            fatalError("Unable to open the database: \(error)")
        }
    }

    private var appVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: Self.appVersionKey) as? String ?? ""
    }
}

extension AppDIContainer {
    func buildSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(observeGymEquipment: observeGymEquipmentUseCase, appVersion: appVersion)
    }

    func buildGymViewModel() -> GymViewModel {
        return GymViewModel(observeGymEquipment: observeGymEquipmentUseCase)
    }

    func buildEquipmentEditorViewModel(target: EquipmentEditorTarget) -> EquipmentEditorViewModel {
        return EquipmentEditorViewModel(
            target: target,
            loadEquipmentEditor: loadEquipmentEditorUseCase,
            saveEquipment: saveEquipmentUseCase,
            archiveEquipment: archiveEquipmentUseCase
        )
    }

    func buildProgramsViewModel() -> ProgramsViewModel {
        return ProgramsViewModel(
            observeExerciseLibrary: observeExerciseLibraryUseCase,
            observePrograms: observeProgramsUseCase,
            deleteProgram: deleteProgramUseCase
        )
    }

    func buildProgramFormViewModel(target: ProgramFormTarget) -> ProgramFormViewModel {
        return ProgramFormViewModel(target: target, createProgram: createProgramUseCase, renameProgram: renameProgramUseCase)
    }

    func buildProgramDayFormViewModel(target: ProgramDayFormTarget) -> ProgramDayFormViewModel {
        return ProgramDayFormViewModel(
            target: target,
            addProgramDay: addProgramDayUseCase,
            updateProgramDay: updateProgramDayUseCase,
            deleteProgramDay: deleteProgramDayUseCase
        )
    }

    func buildProgramDayViewModel(dayId: UUID) -> ProgramDayViewModel {
        return ProgramDayViewModel(
            dayId: dayId,
            observeProgramDay: observeProgramDayUseCase,
            removePlannedExercise: removePlannedExerciseUseCase,
            reorderPlannedExercises: reorderPlannedExercisesUseCase
        )
    }

    func buildPlannedExerciseGoalsViewModel(target: PlannedExerciseGoalsTarget) -> PlannedExerciseGoalsViewModel {
        return PlannedExerciseGoalsViewModel(
            target: target,
            updateTargets: updatePlannedExerciseTargetsUseCase,
            removePlannedExercise: removePlannedExerciseUseCase
        )
    }

    func buildExercisePickerViewModel(target: ExercisePickerTarget) -> ExercisePickerViewModel {
        return ExercisePickerViewModel(
            target: target,
            observeExerciseLibrary: observeExerciseLibraryUseCase,
            observeProgramDay: observeProgramDayUseCase,
            addExerciseToDay: addExerciseToDayUseCase
        )
    }

    func buildLibraryViewModel() -> LibraryViewModel {
        return LibraryViewModel(
            observeExerciseLibrary: observeExerciseLibraryUseCase,
            countProgramDaysUsingExercise: countProgramDaysUsingExerciseUseCase,
            archiveExercise: archiveExerciseUseCase
        )
    }

    func buildAddExerciseViewModel(target: AddExerciseTarget, dayContext: AddExerciseDayContext?) -> AddExerciseViewModel {
        return AddExerciseViewModel(
            target: target,
            dayContext: dayContext,
            observeEquipmentChoices: observeEquipmentChoicesUseCase,
            createExercise: createExerciseUseCase,
            addExerciseToDay: addExerciseToDayUseCase
        )
    }
}
