import Foundation
import WorkoutActivity

enum WorkoutActivityPreviewData {
    private static let elapsedWorkoutSeconds: TimeInterval = -2_052
    private static let restSeconds: TimeInterval = 120
    private static let restElapsedSeconds: TimeInterval = -15
    private static let timedSetSeconds: TimeInterval = 60
    private static let barPlateRgb = 0x1F5FBF
    private static let barPlateKilograms = 20.0
    private static let smallPlateRgb = 0xD7261E
    private static let smallPlateKilograms = 2.5

    static let attributes = WorkoutActivityAttributes(
        workoutId: UUID(),
        startedAt: Date().addingTimeInterval(elapsedWorkoutSeconds)
    )

    static let set = content(phase: .set, restStartedAt: nil)

    static let rest = content(phase: .rest, restStartedAt: Date().addingTimeInterval(restElapsedSeconds))

    static let timedSet = WorkoutActivityContent(
        phase: .timedSet,
        exerciseName: "Планка",
        setText: "подход 2",
        loadText: "1:00",
        nextText: "",
        readyText: "",
        restStartedAt: nil,
        restEndsAt: nil,
        plates: [],
        setStartedAt: Date().addingTimeInterval(restElapsedSeconds),
        setTargetEndsAt: Date().addingTimeInterval(restElapsedSeconds + timedSetSeconds)
    )

    static let finishedSets = WorkoutActivityContent(
        phase: .finishedSets,
        exerciseName: "",
        setText: "",
        loadText: "",
        nextText: "",
        readyText: "Можно завершать тренировку",
        restStartedAt: nil,
        restEndsAt: nil,
        plates: []
    )

    private static func content(phase: WorkoutActivityPhase, restStartedAt: Date?) -> WorkoutActivityContent {
        return WorkoutActivityContent(
            phase: phase,
            exerciseName: "Жим лёжа",
            setText: "подход 4 · 8–12 повт.",
            loadText: "65 × 8",
            nextText: "дальше 65 × 8",
            readyText: "Пора: Жим лёжа, подход 4",
            restStartedAt: restStartedAt,
            restEndsAt: restStartedAt?.addingTimeInterval(restSeconds),
            plates: [
                WorkoutActivityPlate(rgb: barPlateRgb, kilograms: barPlateKilograms),
                WorkoutActivityPlate(rgb: smallPlateRgb, kilograms: smallPlateKilograms),
            ]
        )
    }
}
