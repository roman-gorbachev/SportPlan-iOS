import DesignSystem
import SwiftUI
import WorkoutActivity

struct WorkoutIslandMinimalView: View {
    let state: WorkoutActivityDisplayState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        return Group {
            if case let .rest(interval) = state, !reduceMotion {
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
}
