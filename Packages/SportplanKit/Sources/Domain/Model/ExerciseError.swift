public enum ExerciseError: Error, Equatable, Sendable {
    case invalidDraft(Set<ExerciseValidationIssue>)
    case equipmentUnavailable
    case notFound
    case loadKindChanged
    case metricLocked
}
