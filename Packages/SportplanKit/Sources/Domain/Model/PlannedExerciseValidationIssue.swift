public enum PlannedExerciseValidationIssue: Hashable, Sendable {
    case setsOutOfRange
    case missingReps
    case repsOutOfRange
    case repsNotAllowed
    case restOutOfRange
}
