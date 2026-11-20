import Foundation

public struct WorkoutPreview: Hashable, Sendable {
    public let detail: ProgramDayDetail
    public let lastWorkoutAt: Date?
    public let exercises: [WorkoutPreviewExercise]
    public let tip: WorkoutPreviewTip?

    public init(
        detail: ProgramDayDetail,
        lastWorkoutAt: Date?,
        exercises: [WorkoutPreviewExercise],
        tip: WorkoutPreviewTip?
    ) {
        self.detail = detail
        self.lastWorkoutAt = lastWorkoutAt
        self.exercises = exercises
        self.tip = tip
    }
}
