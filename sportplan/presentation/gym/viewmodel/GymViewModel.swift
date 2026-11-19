import Domain
import Foundation
import Observation

@Observable
final class GymViewModel {
    @ObservationIgnored private let observeGymEquipment: ObserveGymEquipmentUseCase
    @ObservationIgnored private let observePlates: ObservePlatesUseCase
    @ObservationIgnored private let resetPlatesToStandard: ResetPlatesToStandardUseCase
    @ObservationIgnored private var equipment: [Equipment]?
    @ObservationIgnored private var plates: [Plate]?

    private(set) var gymUiState: GymUiState = .loading

    init(
        observeGymEquipment: ObserveGymEquipmentUseCase,
        observePlates: ObservePlatesUseCase,
        resetPlatesToStandard: ResetPlatesToStandardUseCase
    ) {
        self.observeGymEquipment = observeGymEquipment
        self.observePlates = observePlates
        self.resetPlatesToStandard = resetPlatesToStandard
    }

    func observe() async {
        do {
            try await withThrowingDiscardingTaskGroup { group in
                group.addTask {
                    for try await equipment in self.observeGymEquipment.execute() {
                        await self.receive(equipment: equipment)
                    }
                }
                group.addTask {
                    for try await plates in self.observePlates.execute() {
                        await self.receive(plates: plates)
                    }
                }
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            gymUiState = .error(error: error)
        }
    }

    func resetPlates() async {
        do {
            try await resetPlatesToStandard.execute()
        } catch {
            updateData { data in
                data.isShowingResetError = true
            }
        }
    }

    func dismissResetError() {
        updateData { data in
            data.isShowingResetError = false
        }
    }

    private func receive(equipment: [Equipment]) {
        self.equipment = equipment
        rebuild()
    }

    private func receive(plates: [Plate]) {
        self.plates = plates
        rebuild()
    }

    private func rebuild() {
        guard let equipment, let plates else {
            return
        }
        var isShowingResetError = false
        if case let .success(data) = gymUiState {
            isShowingResetError = data.isShowingResetError
        }
        gymUiState = .success(data: GymUiData(
            items: equipment.map(Self.makeItem),
            plates: plates.map(Self.makePlateItem),
            isShowingResetError: isShowingResetError
        ))
    }

    private func updateData(_ change: (inout GymUiData) -> Void) {
        guard case var .success(data) = gymUiState else {
            return
        }
        change(&data)
        gymUiState = .success(data: data)
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

    private static func makePlateItem(_ plate: Plate) -> GymPlateItem {
        return GymPlateItem(
            id: plate.id,
            plate: PlateFormatting.stackItem(plate),
            weightText: PlateFormatting.weightText(plate.weight),
            colorText: PlateFormatting.colorName(plate.color).localizedLowercase
        )
    }
}
