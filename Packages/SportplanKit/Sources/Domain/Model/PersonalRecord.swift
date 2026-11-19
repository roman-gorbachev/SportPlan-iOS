import Foundation

public struct PersonalRecord: Hashable, Sendable {
    public let kind: PersonalRecordKind
    public let entry: SetEntry
    public let value: Int
    public let date: Date

    public init(kind: PersonalRecordKind, entry: SetEntry, value: Int, date: Date) {
        self.kind = kind
        self.entry = entry
        self.value = value
        self.date = date
    }
}
