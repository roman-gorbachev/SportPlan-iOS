public enum ProgramError: Error, Equatable, Sendable {
    case invalidDraft(Set<ProgramValidationIssue>)
    case invalidTargets(Set<PlannedExerciseValidationIssue>)
    case notFound
    case exerciseAlreadyInDay
    case exerciseUnavailable
}
