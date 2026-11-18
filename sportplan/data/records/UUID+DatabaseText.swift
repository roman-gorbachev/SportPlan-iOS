import Foundation

nonisolated extension UUID {
    var databaseText: String {
        return uuidString.lowercased()
    }
}
