public enum BackupError: Error, Equatable, Sendable {
    case unreadable
    case newerVersion
    case invalidData
    case workoutInProgress
}
