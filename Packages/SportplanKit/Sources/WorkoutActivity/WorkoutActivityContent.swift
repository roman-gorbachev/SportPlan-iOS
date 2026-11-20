import Foundation

public struct WorkoutActivityContent: Codable, Hashable, Sendable {
    public let phase: WorkoutActivityPhase
    public let exerciseName: String
    public let setText: String
    public let loadText: String
    public let nextText: String
    public let readyText: String
    public let restStartedAt: Date?
    public let restEndsAt: Date?
    public let plates: [WorkoutActivityPlate]
    public let setStartedAt: Date?
    public let setTargetEndsAt: Date?

    public init(
        phase: WorkoutActivityPhase,
        exerciseName: String,
        setText: String,
        loadText: String,
        nextText: String,
        readyText: String,
        restStartedAt: Date?,
        restEndsAt: Date?,
        plates: [WorkoutActivityPlate],
        setStartedAt: Date? = nil,
        setTargetEndsAt: Date? = nil
    ) {
        self.phase = phase
        self.exerciseName = exerciseName
        self.setText = setText
        self.loadText = loadText
        self.nextText = nextText
        self.readyText = readyText
        self.restStartedAt = restStartedAt
        self.restEndsAt = restEndsAt
        self.plates = plates
        self.setStartedAt = setStartedAt
        self.setTargetEndsAt = setTargetEndsAt
    }
}
