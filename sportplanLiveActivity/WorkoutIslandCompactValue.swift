import DesignSystem
import SwiftUI
import WorkoutActivity

struct WorkoutIslandCompactValue: View {
    private static let timerWidth: CGFloat = 44

    let startedAt: Date
    let content: WorkoutActivityContent
    let state: WorkoutActivityDisplayState

    var body: some View {
        return Group {
            switch state {
            case .set:
                Text(content.loadText)
                    .appStyle(Typography.numeralS)
            case let .rest(interval):
                Text(timerInterval: interval, countsDown: true)
                    .appStyle(Typography.numeralS)
                    .multilineTextAlignment(.trailing)
                    .frame(width: Self.timerWidth, alignment: .trailing)
            case .restOver:
                Text("activity.ready")
                    .appStyle(Typography.callout)
            case .finishedSets:
                Text(startedAt, style: .timer)
                    .appStyle(Typography.numeralS)
                    .multilineTextAlignment(.trailing)
                    .frame(width: Self.timerWidth, alignment: .trailing)
            }
        }
        .lineLimit(1)
        .foregroundStyle(Palette.textPrimary)
    }
}
