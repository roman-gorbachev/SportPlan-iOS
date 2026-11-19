import ActivityKit
import DesignSystem
import SwiftUI
import WidgetKit
import WorkoutActivity

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        return ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            return WorkoutLockScreenView(
                startedAt: context.attributes.startedAt,
                content: context.state,
                state: Self.displayState(context: context)
            )
            .activityBackgroundTint(Palette.surface)
            .activitySystemActionForegroundColor(Palette.textPrimary)
        } dynamicIsland: { context in
            return Self.dynamicIsland(context: context)
        }
    }

    private static func displayState(context: ActivityViewContext<WorkoutActivityAttributes>) -> WorkoutActivityDisplayState {
        return WorkoutActivityDisplayState(content: context.state, isStale: context.isStale)
    }

    private static func dynamicIsland(context: ActivityViewContext<WorkoutActivityAttributes>) -> DynamicIsland {
        let state = displayState(context: context)
        let startedAt = context.attributes.startedAt
        let content = context.state
        return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                return WorkoutIslandExpandedTitle(content: content, state: state)
                    .environment(\.colorScheme, .dark)
            }
            DynamicIslandExpandedRegion(.trailing) {
                return WorkoutIslandExpandedDetail(startedAt: startedAt, content: content, state: state)
                    .environment(\.colorScheme, .dark)
            }
            DynamicIslandExpandedRegion(.bottom) {
                return WorkoutIslandExpandedBody(content: content, state: state)
                    .environment(\.colorScheme, .dark)
            }
        } compactLeading: {
            return WorkoutIslandSymbol(state: state)
                .environment(\.colorScheme, .dark)
        } compactTrailing: {
            return WorkoutIslandCompactValue(startedAt: startedAt, content: content, state: state)
                .environment(\.colorScheme, .dark)
        } minimal: {
            return WorkoutIslandMinimalView(state: state)
                .environment(\.colorScheme, .dark)
        }
        .keylineTint(Palette.accent)
    }
}

#Preview("Lock screen", as: .content, using: WorkoutActivityPreviewData.attributes) {
    FontRegistry.registerFonts()
    return WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityPreviewData.set
    WorkoutActivityPreviewData.rest
    WorkoutActivityPreviewData.finishedSets
}

#Preview("Island expanded", as: .dynamicIsland(.expanded), using: WorkoutActivityPreviewData.attributes) {
    FontRegistry.registerFonts()
    return WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityPreviewData.set
    WorkoutActivityPreviewData.rest
    WorkoutActivityPreviewData.finishedSets
}

#Preview("Island compact", as: .dynamicIsland(.compact), using: WorkoutActivityPreviewData.attributes) {
    FontRegistry.registerFonts()
    return WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityPreviewData.set
    WorkoutActivityPreviewData.rest
    WorkoutActivityPreviewData.finishedSets
}

#Preview("Island minimal", as: .dynamicIsland(.minimal), using: WorkoutActivityPreviewData.attributes) {
    FontRegistry.registerFonts()
    return WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityPreviewData.rest
}
