import Domain
import Foundation

enum EquipmentFormatting {
    static func weightsText(_ equipment: Equipment) -> String {
        let step = WeightFormatting.kilograms(equipment.weightStep)
        guard equipment.kind.hasBaseWeight else {
            return String(localized: "gym.row.stepShort \(step)")
        }
        let base = WeightFormatting.kilograms(equipment.baseWeight)
        if equipment.kind == .plateLoadedMachine {
            return String(localized: "gym.row.platformPair \(base) \(step)")
        }
        return String(localized: "gym.row.weightsPair \(base) \(step)")
    }

    static func weightsAccessibilityText(_ equipment: Equipment) -> String {
        let step = WeightFormatting.kilograms(equipment.weightStep)
        guard equipment.kind.hasBaseWeight else {
            return String(localized: "gym.row.step \(step)")
        }
        let base = WeightFormatting.kilograms(equipment.baseWeight)
        if equipment.kind == .plateLoadedMachine {
            return String(localized: "gym.row.platformWeights \(base) \(step)")
        }
        return String(localized: "gym.row.barWeights \(base) \(step)")
    }
}
