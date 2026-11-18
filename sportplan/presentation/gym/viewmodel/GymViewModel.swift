import Domain
import Foundation
import Observation

@Observable
final class GymViewModel {
    @ObservationIgnored private let observeGymEquipment: ObserveGymEquipmentUseCase

    private(set) var gymUiState: GymUiState = .loading

    init(observeGymEquipment: ObserveGymEquipmentUseCase) {
        self.observeGymEquipment = observeGymEquipment
    }

    func observe() async {
        do {
            for try await equipment in observeGymEquipment.execute() {
                gymUiState = .success(data: GymUiData(items: equipment.map(Self.makeItem)))
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            gymUiState = .error(error: error)
        }
    }

    private static func makeItem(_ equipment: Equipment) -> GymEquipmentItem {
        return GymEquipmentItem(
            id: equipment.id,
            name: equipment.name,
            kindTitle: equipment.kind.listTitle,
            weightsText: EquipmentFormatting.weightsText(equipment),
            weightsAccessibilityText: EquipmentFormatting.weightsAccessibilityText(equipment)
        )
    }
}
