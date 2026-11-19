import Foundation

public protocol WorkoutActivityController: Sendable {
    func show(attributes: WorkoutActivityAttributes, content: WorkoutActivityContent, staleDate: Date?) async
    func end() async
}
