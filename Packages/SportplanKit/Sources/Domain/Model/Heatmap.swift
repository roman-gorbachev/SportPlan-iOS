import Foundation

public struct Heatmap: Hashable, Sendable {
    public let weeks: [HeatmapWeek]

    public init(weeks: [HeatmapWeek]) {
        self.weeks = weeks
    }

    public var workoutCount: Int {
        return weeks.reduce(.zero) { total, week in
            return total + week.days.reduce(.zero) { dayTotal, day in
                return dayTotal + day.workoutIds.count
            }
        }
    }

    public func day(containing date: Date) -> HeatmapDay? {
        for week in weeks {
            if let day = week.days.first(where: { day in return day.date == date }) {
                return day
            }
        }
        return nil
    }
}
