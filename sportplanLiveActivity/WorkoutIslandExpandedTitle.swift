import DesignSystem
import SwiftUI
import WorkoutActivity

struct WorkoutIslandExpandedTitle: View {
    let content: WorkoutActivityContent
    let state: WorkoutActivityDisplayState

    var body: some View {
        return HStack(spacing: Spacing.xs) {
            WorkoutIslandSymbol(state: state)
            title
                .appStyle(Typography.callout)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
        }
        .padding(.leading, Spacing.xs)
    }

    private var title: Text {
        switch state {
        case .set:
            return Text(content.exerciseName)
        case .rest:
            return Text("activity.rest")
        case .restOver:
            return Text("activity.rest.over")
        case .finishedSets:
            return Text("activity.sets.done")
        }
    }
}
