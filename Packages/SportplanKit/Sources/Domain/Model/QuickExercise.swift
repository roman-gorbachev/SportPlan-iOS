public enum QuickExercise: Hashable, Sendable, CaseIterable {
    case benchPress
    case squat
    case deadlift
    case pullUp
    case dip
    case legPress
    case plank

    public var loadKind: ExerciseLoadKind {
        switch self {
        case .benchPress, .squat, .deadlift:
            return .equipment(.barbell)
        case .legPress:
            return .equipment(.plateLoadedMachine)
        case .pullUp, .dip, .plank:
            return .bodyweight
        }
    }

    public var metric: ExerciseMetric {
        switch self {
        case .plank:
            return .duration
        case .benchPress, .squat, .deadlift, .pullUp, .dip, .legPress:
            return .weightReps
        }
    }
}
