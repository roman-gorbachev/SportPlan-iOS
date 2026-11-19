import Domain
import Observation

@Observable
final class SettingsViewModel {
    @ObservationIgnored private let observeGymEquipment: ObserveGymEquipmentUseCase
    @ObservationIgnored private let observePlates: ObservePlatesUseCase
    @ObservationIgnored private let appVersion: String
    @ObservationIgnored private var equipmentCount: Int?
    @ObservationIgnored private var plateCount: Int?

    private(set) var settingsUiState: SettingsUiState = .loading

    init(observeGymEquipment: ObserveGymEquipmentUseCase, observePlates: ObservePlatesUseCase, appVersion: String) {
        self.observeGymEquipment = observeGymEquipment
        self.observePlates = observePlates
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
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            settingsUiState = .error(error: error)
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
        settingsUiState = .success(data: SettingsUiData(equipmentCount: equipmentCount, plateCount: plateCount, appVersion: appVersion))
    }
}
