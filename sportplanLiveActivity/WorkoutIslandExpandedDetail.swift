import DesignSystem
import SwiftUI
import WorkoutActivity

struct WorkoutIslandExpandedDetail: View {
    let startedAt: Date
    let content: WorkoutActivityContent
    let state: WorkoutActivityDisplayState

    var body: some View {
        return Group {
            switch state {
            case .set:
                EmptyView()
            case .rest:
                Text(content.nextText)
            case let .restOver(endedAt):
                HStack(spacing: Spacing.xxs) {
                    Text("activity.rest.elapsed")
                    Text(endedAt, style: .timer)
                        .monospacedDigit()
                        .foregroundStyle(Palette.textPrimary)
                }
                .accessibilityElement(children: .combine)
            case .finishedSets:
                WorkoutElapsedText(startedAt: startedAt)
            case .timedSet, .timedSetRunning:
                Text(content.setText)
            case .timedSetOver:
                Text(content.exerciseName)
            }
        }
        .appStyle(Typography.footnote)
        .foregroundStyle(Palette.textSecondary)
        .lineLimit(1)
        .padding(.trailing, Spacing.xs)
    }
}
