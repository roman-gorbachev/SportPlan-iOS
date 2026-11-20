import DesignSystem
import SwiftUI
import WorkoutActivity

struct WorkoutIslandMinimalView: View {
    let state: WorkoutActivityDisplayState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        return Group {
            if let interval = countdownInterval, !reduceMotion {
                ProgressView(timerInterval: interval, countsDown: true) {
                    return EmptyView()
                } currentValueLabel: {
                    return EmptyView()
                }
                .progressViewStyle(.circular)
                .tint(Palette.accent)
                .accessibilityHidden(true)
            } else {
                WorkoutIslandSymbol(state: state)
            }
        }
    }

    private var countdownInterval: ClosedRange<Date>? {
        switch state {
        case let .rest(interval), let .timedSet(interval):
            return interval
        case .set, .restOver, .finishedSets, .timedSetOver, .timedSetRunning:
            return nil
        }
    }
}
