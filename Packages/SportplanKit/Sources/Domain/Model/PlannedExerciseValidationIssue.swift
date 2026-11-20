public enum PlannedExerciseValidationIssue: Hashable, Sendable {
    case setsOutOfRange
    case missingReps
    case repsOutOfRange
    case repsNotAllowed
    case restOutOfRange
    case startWeightNotAllowed
    case startWeightOutOfRange
    case durationOutOfRange
    case durationNotAllowed
}
