import Domain
import Foundation

final class AppDIContainer {
    private static let appVersionKey = "CFBundleShortVersionString"

    private let appDatabase: AppDatabase

    private lazy var equipmentRepository: any EquipmentRepository = EquipmentRepositoryImpl(database: appDatabase)
    private lazy var exerciseRepository: any ExerciseRepository = ExerciseRepositoryImpl(database: appDatabase)

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
        return ProgramsViewModel(observeExerciseLibrary: observeExerciseLibraryUseCase)
    }

    func buildLibraryViewModel() -> LibraryViewModel {
        return LibraryViewModel(
            observeExerciseLibrary: observeExerciseLibraryUseCase,
            countProgramDaysUsingExercise: countProgramDaysUsingExerciseUseCase,
            archiveExercise: archiveExerciseUseCase
        )
    }

    func buildAddExerciseViewModel(target: AddExerciseTarget) -> AddExerciseViewModel {
        return AddExerciseViewModel(
            target: target,
            observeEquipmentChoices: observeEquipmentChoicesUseCase,
            createExercise: createExerciseUseCase
        )
    }
}
