public enum EquipmentKind: String, CaseIterable, Sendable {
    case barbell
    case dumbbell
    case plateLoadedMachine = "plate_loaded_machine"
    case selectorizedMachine = "selectorized_machine"

    public var hasBaseWeight: Bool {
        switch self {
        case .barbell, .plateLoadedMachine:
            return true
        case .dumbbell, .selectorizedMachine:
            return false
        }
    }

    public var usesPlates: Bool {
        switch self {
        case .barbell, .plateLoadedMachine:
            return true
        case .dumbbell, .selectorizedMachine:
            return false
        }
    }
}
