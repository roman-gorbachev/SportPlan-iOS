public enum ExerciseLoadKind: Hashable, Sendable, CaseIterable {
    case equipment(EquipmentKind)
    case bodyweight

    public static var allCases: [ExerciseLoadKind] {
        return EquipmentKind.allCases.map { kind in
            return ExerciseLoadKind.equipment(kind)
        } + [.bodyweight]
    }

    public var equipmentKind: EquipmentKind? {
        switch self {
        case let .equipment(kind):
            return kind
        case .bodyweight:
            return nil
        }
    }

    public var allowsDuration: Bool {
        return self == .bodyweight
    }
}
