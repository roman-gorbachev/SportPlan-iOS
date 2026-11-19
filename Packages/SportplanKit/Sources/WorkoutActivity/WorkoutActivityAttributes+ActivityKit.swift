#if os(iOS)
import ActivityKit

extension WorkoutActivityAttributes: ActivityAttributes {
    public typealias ContentState = WorkoutActivityContent
}
#endif
