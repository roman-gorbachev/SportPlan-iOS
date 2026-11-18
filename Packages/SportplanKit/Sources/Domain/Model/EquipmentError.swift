public enum EquipmentError: Error, Equatable, Sendable {
    case invalidDraft(Set<EquipmentValidationIssue>)
    case kindLocked
    case notFound
}
