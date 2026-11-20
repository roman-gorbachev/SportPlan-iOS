import DesignSystem
import SwiftUI

struct TimedSetCountdown: View {
    private static let tickSeconds: TimeInterval = 1

    let startedAt: Date
    let endsAt: Date

    var body: some View {
        return TimelineView(.periodic(from: startedAt, by: Self.tickSeconds)) { context in
            let isOver = context.date >= endsAt
            return Text(text(at: context.date, isOver: isOver))
                .appStyle(Typography.numeralL)
                .foregroundStyle(isOver ? Palette.success : Palette.textPrimary)
                .sensoryFeedback(.warning, trigger: isOver) { _, newValue in
                    return newValue
                }
        }
    }

    private func text(at date: Date, isOver: Bool) -> String {
        let seconds = Int(abs(endsAt.timeIntervalSince(date)).rounded())
        let clock = WorkoutFormatting.duration(seconds: seconds)
        guard isOver else {
            return clock
        }
        return String(localized: "workout.set.overtime \(clock)")
    }
}
