import ActivityKit
import SwiftUI
import WidgetKit
import WorkoutActivity

struct WorkoutLiveActivity: Widget {
    private static let symbolName = "dumbbell.fill"

    var body: some WidgetConfiguration {
        return ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            return Self.lockScreen(context: context)
        } dynamicIsland: { context in
            return Self.dynamicIsland(context: context)
        }
    }

    private static func lockScreen(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        return Text(context.state.exerciseName)
    }

    private static func dynamicIsland(context: ActivityViewContext<WorkoutActivityAttributes>) -> DynamicIsland {
        return DynamicIsland {
            DynamicIslandExpandedRegion(.center) {
                return Text(context.state.exerciseName)
            }
        } compactLeading: {
            return Image(systemName: symbolName)
        } compactTrailing: {
            return Text(context.state.loadText)
        } minimal: {
            return Image(systemName: symbolName)
        }
    }
}
