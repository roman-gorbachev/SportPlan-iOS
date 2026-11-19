import ActivityKit
import Foundation
import Synchronization
import WorkoutActivity

nonisolated final class WorkoutActivityControllerImpl: WorkoutActivityController {
    private let requestedWorkoutIds = Mutex<Set<UUID>>([])

    func show(attributes: WorkoutActivityAttributes, content: WorkoutActivityContent, staleDate: Date?) async {
        let activityContent = ActivityContent(state: content, staleDate: staleDate)
        let activities = Activity<WorkoutActivityAttributes>.activities
        if let current = activities.first(where: { activity in return Self.isShowing(activity, workoutId: attributes.workoutId) }) {
            await current.update(activityContent)
            return
        }
        for activity in activities where activity.attributes.workoutId != attributes.workoutId {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        let alreadyRequested = requestedWorkoutIds.withLock { ids in
            return ids.contains(attributes.workoutId)
        }
        guard !alreadyRequested, ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }
        guard (try? Activity.request(attributes: attributes, content: activityContent, pushType: nil)) != nil else {
            return
        }
        requestedWorkoutIds.withLock { ids in
            ids.formUnion([attributes.workoutId])
        }
    }

    func end() async {
        for activity in Activity<WorkoutActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private static func isShowing(_ activity: Activity<WorkoutActivityAttributes>, workoutId: UUID) -> Bool {
        guard activity.attributes.workoutId == workoutId else {
            return false
        }
        switch activity.activityState {
        case .active, .stale:
            return true
        case .pending, .ended, .dismissed:
            return false
        @unknown default:
            return false
        }
    }
}
