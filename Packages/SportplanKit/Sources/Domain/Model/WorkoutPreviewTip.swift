public enum WorkoutPreviewTip: Hashable, Sendable {
    case progression(exerciseName: String, weight: Weight)
    case firstWorkout
    case longBreak(days: Int)
}
