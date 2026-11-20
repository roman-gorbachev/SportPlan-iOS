import Domain
import Foundation
import Observation

@Observable
final class SettingsViewModel {
    @ObservationIgnored private let observeGymEquipment: ObserveGymEquipmentUseCase
    @ObservationIgnored private let observePlates: ObservePlatesUseCase
    @ObservationIgnored private let exportBackup: ExportBackupUseCase
    @ObservationIgnored private let readBackup: ReadBackupUseCase
    @ObservationIgnored private let importBackup: ImportBackupUseCase
    @ObservationIgnored private let workoutStore: ActiveWorkoutStore
    @ObservationIgnored private let appVersion: String
    @ObservationIgnored private var equipmentCount: Int?
    @ObservationIgnored private var plateCount: Int?
    @ObservationIgnored private var isImportAvailable = false
    @ObservationIgnored private var importStep: SettingsImportStep = .idle
    @ObservationIgnored private var candidate: BackupCandidate?
    @ObservationIgnored private var importTask: Task<Void, Never>?

    private(set) var settingsUiState: SettingsUiState = .loading

    init(
        observeGymEquipment: ObserveGymEquipmentUseCase,
        observePlates: ObservePlatesUseCase,
        exportBackup: ExportBackupUseCase,
        readBackup: ReadBackupUseCase,
        importBackup: ImportBackupUseCase,
        workoutStore: ActiveWorkoutStore,
        appVersion: String
    ) {
        self.observeGymEquipment = observeGymEquipment
        self.observePlates = observePlates
        self.exportBackup = exportBackup
        self.readBackup = readBackup
        self.importBackup = importBackup
        self.workoutStore = workoutStore
        self.appVersion = appVersion
    }

    func observe() async {
        do {
            try await withThrowingDiscardingTaskGroup { group in
                group.addTask {
                    for try await equipment in self.observeGymEquipment.execute() {
                        await self.receive(equipmentCount: equipment.count)
                    }
                }
                group.addTask {
                    for try await plates in self.observePlates.execute() {
                        await self.receive(plateCount: plates.count)
                    }
                }
                group.addTask {
                    await self.observeImportAvailability()
                }
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            settingsUiState = .error(error: error)
        }
    }

    func export() async throws -> BackupExport {
        return try await exportBackup.execute()
    }

    func readImport(fileURL: URL) async {
        do {
            let candidate = try await readBackup.execute(fileURL: fileURL)
            self.candidate = candidate
            importStep = .confirming(message: SettingsFormatting.importMessage(candidate.summary))
        } catch {
            importStep = .failed(message: SettingsFormatting.importError(error))
        }
        rebuild()
    }

    func failImportFile() {
        candidate = nil
        importStep = .failed(message: SettingsFormatting.importError(BackupError.unreadable))
        rebuild()
    }

    func confirmImport() {
        guard let candidate, importTask == nil else {
            return
        }
        self.candidate = nil
        importStep = .importing
        rebuild()
        importTask = Task {
            await performImport(candidate)
        }
    }

    func cancelImport() {
        candidate = nil
        importStep = .idle
        rebuild()
    }

    @discardableResult
    func dismissImportResult() -> Bool {
        let didImport = importStep == .finished
        importStep = .idle
        rebuild()
        return didImport
    }

    private func performImport(_ candidate: BackupCandidate) async {
        do {
            try await importBackup.execute(candidate: candidate)
            importStep = .finished
        } catch {
            importStep = .failed(message: SettingsFormatting.importError(error))
        }
        importTask = nil
        rebuild()
    }

    private func observeImportAvailability() async {
        let store = workoutStore
        let availability = Observations {
            guard case .noWorkout = store.state else {
                return false
            }
            return true
        }
        for await isAvailable in availability {
            isImportAvailable = isAvailable
            rebuild()
        }
    }

    private func receive(equipmentCount: Int) {
        self.equipmentCount = equipmentCount
        rebuild()
    }

    private func receive(plateCount: Int) {
        self.plateCount = plateCount
        rebuild()
    }

    private func rebuild() {
        guard let equipmentCount, let plateCount else {
            return
        }
        settingsUiState = .success(data: SettingsUiData(
            equipmentCount: equipmentCount,
            plateCount: plateCount,
            appVersion: appVersion,
            isImportAvailable: isImportAvailable,
            importStep: importStep
        ))
    }
}
