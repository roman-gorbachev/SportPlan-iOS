import Foundation

struct WorkoutStartProgramItem: Identifiable {
    let id: UUID
    let title: String
    let nextDay: WorkoutStartNextDayItem
    let otherDays: [WorkoutStartDayItem]
}
