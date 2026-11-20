import Domain
import Foundation
import WorkoutActivity

final class AppDIContainer {
    private static let appVersionKey = "CFBundleShortVersionString"

    private let appDatabase: AppDatabase
    private let restNotificationCenter = RestNotificationCenter(soundPlayer: AlertSoundPlayer())

    private lazy var equipmentRepository: any EquipmentRepository = EquipmentRepositoryImpl(database: appDatabase)
    private lazy var exerciseRepository: any ExerciseRepository = ExerciseRepositoryImpl(database: appDatabase)
    private lazy var programRepository: any ProgramRepository = ProgramRepositoryImpl(database: appDatabase)
    private lazy var workoutRepository: any WorkoutRepository = WorkoutRepositoryImpl(database: appDatabase)
    private lazy var plateRepository: any PlateRepository = PlateRepositoryImpl(database: appDatabase)

    private lazy var observeGymEquipmentUseCase = ObserveGymEquipmentUseCase(repository: equipmentRepository)
    private lazy var loadEquipmentEditorUseCase = LoadEquipmentEditorUseCase(repository: equipmentRepository)
    private lazy var saveEquipmentUseCase = SaveEquipmentUseCase(repository: equipmentRepository, now: { return Date() })
    private lazy var archiveEquipmentUseCase = ArchiveEquipmentUseCase(repository: equipmentRepository)

    private lazy var observePlatesUseCase = ObservePlatesUseCase(repository: plateRepository)
    private lazy var loadPlateEditorUseCase = LoadPlateEditorUseCase(repository: plateRepository)
    private lazy var savePlateUseCase = SavePlateUseCase(repository: plateRepository)
    private lazy var deletePlateUseCase = DeletePlateUseCase(repository: plateRepository)
    private lazy var resetPlatesToStandardUseCase = ResetPlatesToStandardUseCase(repository: plateRepository)

    private lazy var observeExerciseLibraryUseCase = ObserveExerciseLibraryUseCase(repository: exerciseRepository)
    private lazy var observeExerciseCardUseCase = ObserveExerciseCardUseCase(repository: workoutRepository)
    private lazy var observeEquipmentChoicesUseCase = ObserveEquipmentChoicesUseCase(repository: equipmentRepository)
    private lazy var createExerciseUseCase = CreateExerciseUseCase(
        exerciseRepository: exerciseRepository,
        equipmentRepository: equipmentRepository,
        now: { return Date() }
    )
    private lazy var countProgramDaysUsingExerciseUseCase = CountProgramDaysUsingExerciseUseCase(repository: exerciseRepository)
    private lazy var archiveExerciseUseCase = ArchiveExerciseUseCase(repository: exerciseRepository)
    private lazy var loadExerciseEditorUseCase = LoadExerciseEditorUseCase(
        exerciseRepository: exerciseRepository,
        equipmentRepository: equipmentRepository
    )
    private lazy var updateExerciseUseCase = UpdateExerciseUseCase(
        exerciseRepository: exerciseRepository,
        equipmentRepository: equipmentRepository
    )

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

    private lazy var observeActiveWorkoutUseCase = ObserveActiveWorkoutUseCase(repository: workoutRepository)
    private lazy var startWorkoutFromDayUseCase = StartWorkoutFromDayUseCase(
        workoutRepository: workoutRepository,
        programRepository: programRepository,
        now: { return Date() }
    )
    private lazy var loadWorkoutPreviewUseCase = LoadWorkoutPreviewUseCase(
        workoutRepository: workoutRepository,
        programRepository: programRepository,
        now: { return Date() }
    )
    private lazy var startEmptyWorkoutUseCase = StartEmptyWorkoutUseCase(repository: workoutRepository, now: { return Date() })
    private lazy var addExerciseToWorkoutUseCase = AddExerciseToWorkoutUseCase(
        workoutRepository: workoutRepository,
        exerciseRepository: exerciseRepository,
        equipmentRepository: equipmentRepository
    )
    private lazy var addSetUseCase = AddSetUseCase(repository: workoutRepository)
    private lazy var removeExerciseFromWorkoutUseCase = RemoveExerciseFromWorkoutUseCase(
        repository: workoutRepository,
        scheduler: restNotificationCenter
    )
    private lazy var updateSetUseCase = UpdateSetUseCase(repository: workoutRepository)
    private lazy var completeSetUseCase = CompleteSetUseCase(
        repository: workoutRepository,
        scheduler: restNotificationCenter,
        now: { return Date() }
    )
    private lazy var startTimedSetUseCase = StartTimedSetUseCase(
        repository: workoutRepository,
        scheduler: restNotificationCenter,
        now: { return Date() }
    )
    private lazy var stopTimedSetUseCase = StopTimedSetUseCase(
        repository: workoutRepository,
        scheduler: restNotificationCenter,
        now: { return Date() }
    )
    private lazy var removeSetUseCase = RemoveSetUseCase(repository: workoutRepository, scheduler: restNotificationCenter)
    private lazy var updateWorkoutNoteUseCase = UpdateWorkoutNoteUseCase(repository: workoutRepository)
    private lazy var finishWorkoutUseCase = FinishWorkoutUseCase(
        repository: workoutRepository,
        scheduler: restNotificationCenter,
        now: { return Date() }
    )
    private lazy var cancelWorkoutUseCase = CancelWorkoutUseCase(repository: workoutRepository, scheduler: restNotificationCenter)
    private lazy var adjustRestUseCase = AdjustRestUseCase(
        repository: workoutRepository,
        scheduler: restNotificationCenter,
        now: { return Date() }
    )
    private lazy var applyProgressionUseCase = ApplyProgressionUseCase(repository: workoutRepository)
    private lazy var skipRestUseCase = SkipRestUseCase(repository: workoutRepository, scheduler: restNotificationCenter)

    private lazy var activeWorkoutStore = ActiveWorkoutStore(observeActiveWorkout: observeActiveWorkoutUseCase)
    private lazy var workoutActivityController: any WorkoutActivityController = WorkoutActivityControllerImpl()
    private lazy var workoutActivityCoordinator = WorkoutActivityCoordinator(
        store: activeWorkoutStore,
        observePlates: observePlatesUseCase,
        controller: workoutActivityController
    )

    init() {
        do {
            appDatabase = try AppDatabase.makePersistent()
        } catch {
            fatalError("Unable to open the database: \(error)")
        }
        restNotificationCenter.activate()
    }

    private var appVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: Self.appVersionKey) as? String ?? ""
    }
}

extension AppDIContainer {
    func observeActiveWorkout() async {
        await activeWorkoutStore.observe()
    }

    func observeWorkoutActivity() async {
        await workoutActivityCoordinator.observe()
    }

    func buildSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(
            observeGymEquipment: observeGymEquipmentUseCase,
            observePlates: observePlatesUseCase,
            appVersion: appVersion
        )
    }

    func buildGymViewModel() -> GymViewModel {
        return GymViewModel(
            observeGymEquipment: observeGymEquipmentUseCase,
            observePlates: observePlatesUseCase,
            resetPlatesToStandard: resetPlatesToStandardUseCase
        )
    }

    func buildPlateEditorViewModel(target: PlateEditorTarget) -> PlateEditorViewModel {
        return PlateEditorViewModel(
            target: target,
            loadPlateEditor: loadPlateEditorUseCase,
            savePlate: savePlateUseCase,
            deletePlate: deletePlateUseCase
        )
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
            deleteProgram: deleteProgramUseCase,
            deleteProgramDay: deleteProgramDayUseCase
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
            addExerciseToDay: addExerciseToDayUseCase,
            workoutStore: activeWorkoutStore,
            addExerciseToWorkout: addExerciseToWorkoutUseCase
        )
    }

    func buildWorkoutStartViewModel() -> WorkoutStartViewModel {
        return WorkoutStartViewModel(observePrograms: observeProgramsUseCase, startEmptyWorkout: startEmptyWorkoutUseCase)
    }

    func buildWorkoutPreviewViewModel(dayId: UUID) -> WorkoutPreviewViewModel {
        return WorkoutPreviewViewModel(
            dayId: dayId,
            loadWorkoutPreview: loadWorkoutPreviewUseCase,
            startWorkoutFromDay: startWorkoutFromDayUseCase
        )
    }

    func buildActiveWorkoutViewModel() -> ActiveWorkoutViewModel {
        return ActiveWorkoutViewModel(
            store: activeWorkoutStore,
            observePlates: observePlatesUseCase,
            addSet: addSetUseCase,
            updateSet: updateSetUseCase,
            completeSet: completeSetUseCase,
            startTimedSet: startTimedSetUseCase,
            stopTimedSet: stopTimedSetUseCase,
            removeSet: removeSetUseCase,
            removeExerciseFromWorkout: removeExerciseFromWorkoutUseCase,
            updateWorkoutNote: updateWorkoutNoteUseCase,
            finishWorkout: finishWorkoutUseCase,
            cancelWorkout: cancelWorkoutUseCase,
            adjustRest: adjustRestUseCase,
            skipRest: skipRestUseCase,
            applyProgression: applyProgressionUseCase
        )
    }

    func buildRestTimerViewModel() -> RestTimerViewModel {
        return RestTimerViewModel(store: activeWorkoutStore, adjustRest: adjustRestUseCase, skipRest: skipRestUseCase)
    }

    func buildLibraryViewModel() -> LibraryViewModel {
        return LibraryViewModel(
            observeExerciseLibrary: observeExerciseLibraryUseCase,
            countProgramDaysUsingExercise: countProgramDaysUsingExerciseUseCase,
            archiveExercise: archiveExerciseUseCase
        )
    }

    func buildExerciseCardViewModel(exerciseId: UUID) -> ExerciseCardViewModel {
        return ExerciseCardViewModel(observeExerciseCard: observeExerciseCardUseCase, exerciseId: exerciseId)
    }

    func buildExerciseEditorViewModel(exerciseId: UUID) -> ExerciseEditorViewModel {
        return ExerciseEditorViewModel(
            exerciseId: exerciseId,
            loadExerciseEditor: loadExerciseEditorUseCase,
            observeEquipmentChoices: observeEquipmentChoicesUseCase,
            updateExercise: updateExerciseUseCase,
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
