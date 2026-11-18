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
        let step = WeightFormatting.kilograms(equipment.weightStep)
        let weightsText: String
        let weightsAccessibilityText: String
        if equipment.kind.hasBaseWeight {
            let base = WeightFormatting.kilograms(equipment.baseWeight)
            weightsText = String(localized: "gym.row.weightsPair \(base) \(step)")
            weightsAccessibilityText = equipment.kind == .plateLoadedMachine
                ? String(localized: "gym.row.platformWeights \(base) \(step)")
                : String(localized: "gym.row.barWeights \(base) \(step)")
        } else {
            weightsText = String(localized: "gym.row.stepShort \(step)")
            weightsAccessibilityText = String(localized: "gym.row.step \(step)")
        }
        return GymEquipmentItem(
            id: equipment.id,
            name: equipment.name,
            kindTitle: equipment.kind.listTitle,
            weightsText: weightsText,
            weightsAccessibilityText: weightsAccessibilityText
        )
    }
}
