import GRDB

nonisolated protocol AppRecord: Codable, FetchableRecord, PersistableRecord {}

nonisolated extension AppRecord {
    static func databaseUUIDEncodingStrategy(for column: String) -> DatabaseUUIDEncodingStrategy {
        return .lowercaseString
    }

    static var databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy {
        return .convertFromSnakeCase
    }

    static var databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy {
        return .convertToSnakeCase
    }
}
