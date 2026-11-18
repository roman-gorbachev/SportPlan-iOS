public enum ExerciseValidationIssue: Hashable, Sendable {
    case emptyName
    case missingEquipment
    case durationNotAllowed
    case restOutOfRange
}
