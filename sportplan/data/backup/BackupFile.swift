import Foundation

nonisolated struct BackupFile: Codable, Sendable {
    static let currentVersion = 1

    var schemaVersion: Int
    var exportedAt: Date
    var equipment: [BackupEquipment]
    var plates: [BackupPlate]
    var exercises: [BackupExercise]
    var programs: [BackupProgram]
    var programDays: [BackupProgramDay]
    var plannedExercises: [BackupPlannedExercise]
    var workouts: [BackupWorkout]
    var workoutExercises: [BackupWorkoutExercise]
    var sets: [BackupSet]
}
