import Foundation

struct WorkoutStartNextDayItem: Identifiable {
    let id: UUID
    let label: String?
    let name: String
    let exercises: String
    let lastWorkout: String
}
