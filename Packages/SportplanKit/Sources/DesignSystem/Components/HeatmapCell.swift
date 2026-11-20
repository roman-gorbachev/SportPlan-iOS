import Foundation

public struct HeatmapCell: Identifiable, Hashable, Sendable {
    public let id: Date
    public let level: Int
    public let isToday: Bool
    public let isFuture: Bool
    public let isSelectable: Bool
    public let accessibilityLabel: String

    public init(id: Date, level: Int, isToday: Bool, isFuture: Bool, isSelectable: Bool, accessibilityLabel: String) {
        self.id = id
        self.level = level
        self.isToday = isToday
        self.isFuture = isFuture
        self.isSelectable = isSelectable
        self.accessibilityLabel = accessibilityLabel
    }
}
