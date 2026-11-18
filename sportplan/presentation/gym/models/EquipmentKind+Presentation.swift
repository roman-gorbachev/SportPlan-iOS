import Domain
import Foundation

extension EquipmentKind {
    var title: String {
        switch self {
        case .barbell:
            return String(localized: "equipment.kind.barbell")
        case .dumbbell:
            return String(localized: "equipment.kind.dumbbell")
        case .plateLoadedMachine:
            return String(localized: "equipment.kind.plateLoadedMachine")
        case .selectorizedMachine:
            return String(localized: "equipment.kind.selectorizedMachine")
        }
    }

    var listTitle: String {
        switch self {
        case .barbell:
            return String(localized: "equipment.kind.barbell.list")
        case .dumbbell:
            return String(localized: "equipment.kind.dumbbell.list")
        case .plateLoadedMachine:
            return String(localized: "equipment.kind.plateLoadedMachine.list")
        case .selectorizedMachine:
            return String(localized: "equipment.kind.selectorizedMachine.list")
        }
    }

    var baseWeightTitle: String {
        switch self {
        case .plateLoadedMachine:
            return String(localized: "equipment.editor.platformWeight")
        case .barbell, .dumbbell, .selectorizedMachine:
            return String(localized: "equipment.editor.barWeight")
        }
    }
}
