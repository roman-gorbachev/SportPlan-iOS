import Foundation

public struct SetEndNotificationRequest: Hashable, Sendable {
    public let endsAt: Date
    public let exerciseName: String
    public let setNumber: Int?

    public init(endsAt: Date, exerciseName: String, setNumber: Int?) {
        self.endsAt = endsAt
        self.exerciseName = exerciseName
        self.setNumber = setNumber
    }
}
