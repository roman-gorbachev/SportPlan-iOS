import Foundation

public struct HistoryOverview: Hashable, Sendable {
    public let heatmap: Heatmap
    public let entries: [HistoryEntry]

    public init(heatmap: Heatmap, entries: [HistoryEntry]) {
        self.heatmap = heatmap
        self.entries = entries
    }

    public init(workouts: [FinishedWorkout], today: Date, calendar: Calendar) {
        let recordSetIds = WorkoutRecords.recordSetIds(in: workouts)
        self.heatmap = HeatmapBuilder.make(workouts: workouts, today: today, calendar: calendar)
        self.entries = workouts
            .sorted { lhs, rhs in
                return lhs.startedAt > rhs.startedAt
            }
            .map { workout in
                return HistoryEntry(workout: workout, recordCount: workout.recordCount(in: recordSetIds))
            }
    }

    public var isEmpty: Bool {
        return entries.isEmpty
    }
}
