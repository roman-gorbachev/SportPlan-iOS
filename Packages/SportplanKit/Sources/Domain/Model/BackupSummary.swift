import Foundation

public struct BackupSummary: Equatable, Sendable {
    public let exportedAt: Date
    public let workoutCount: Int
    public let exerciseCount: Int
    public let programCount: Int

    public init(exportedAt: Date, workoutCount: Int, exerciseCount: Int, programCount: Int) {
        self.exportedAt = exportedAt
        self.workoutCount = workoutCount
        self.exerciseCount = exerciseCount
        self.programCount = programCount
    }
}
