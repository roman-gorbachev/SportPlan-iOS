import Domain

nonisolated extension RepRange {
    static func fromColumns(min: Int?, max: Int?, table: String) throws -> RepRange? {
        switch (min, max) {
        case (nil, nil):
            return nil
        case let (min?, max?):
            guard let range = RepRange(min: min, max: max) else {
                throw RecordMappingError.invalidValue(table: table, column: "target_reps_min")
            }
            return range
        default:
            throw RecordMappingError.invalidValue(table: table, column: "target_reps_min")
        }
    }
}
