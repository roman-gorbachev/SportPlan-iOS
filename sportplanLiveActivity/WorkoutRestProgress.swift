import SwiftUI

struct WorkoutRestProgress: View {
    let interval: ClosedRange<Date>
    let tint: Color

    var body: some View {
        return ProgressView(timerInterval: interval, countsDown: false) {
            return EmptyView()
        } currentValueLabel: {
            return EmptyView()
        }
        .tint(tint)
        .accessibilityHidden(true)
    }
}
