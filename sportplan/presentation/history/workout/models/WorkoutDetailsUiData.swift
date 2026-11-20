import Foundation

struct WorkoutDetailsUiData: Hashable {
    let meta: String
    let title: String
    let durationValue: String
    let setCountValue: String
    let recordCountValue: String
    let hasRecords: Bool
    let exercises: [WorkoutDetailsExerciseItem]
    let note: String?
    let isShowingDeleteError: Bool
}
