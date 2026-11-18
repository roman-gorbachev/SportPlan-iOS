public enum EquipmentValidationIssue: Hashable, Sendable {
    case emptyName
    case baseWeightOutOfRange
    case weightStepOutOfRange
}
