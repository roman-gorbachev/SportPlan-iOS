import Domain
import Observation

@Observable
final class SettingsViewModel {
    @ObservationIgnored private let observeGymEquipment: ObserveGymEquipmentUseCase
    @ObservationIgnored private let appVersion: String

    private(set) var settingsUiState: SettingsUiState = .loading

    init(observeGymEquipment: ObserveGymEquipmentUseCase, appVersion: String) {
        self.observeGymEquipment = observeGymEquipment
        self.appVersion = appVersion
    }

    func observe() async {
        do {
            for try await equipment in observeGymEquipment.execute() {
                settingsUiState = .success(data: SettingsUiData(equipmentCount: equipment.count, appVersion: appVersion))
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            settingsUiState = .error(error: error)
        }
    }
}
