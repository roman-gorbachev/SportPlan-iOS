import Foundation

public struct HeatmapColumn: Identifiable, Hashable, Sendable {
    public let id: Date
    public let monthLabel: String?
    public let cells: [HeatmapCell]

    public init(id: Date, monthLabel: String?, cells: [HeatmapCell]) {
        self.id = id
        self.monthLabel = monthLabel
        self.cells = cells
    }
}
