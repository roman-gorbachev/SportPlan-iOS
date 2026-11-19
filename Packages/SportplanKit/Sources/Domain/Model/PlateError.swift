public enum PlateError: Error, Equatable, Sendable {
    case invalidDraft(Set<PlateValidationIssue>)
    case notFound
}
