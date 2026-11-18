nonisolated enum RecordMappingError: Error, Equatable, Sendable {
    case invalidValue(table: String, column: String)
}
