import Foundation

public struct HeatmapWeek: Identifiable, Hashable, Sendable {
    public let start: Date
    public let days: [HeatmapDay]

    public init(start: Date, days: [HeatmapDay]) {
        self.start = start
        self.days = days
    }

    public var id: Date {
        return start
    }
}
