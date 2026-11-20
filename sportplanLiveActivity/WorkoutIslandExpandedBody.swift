import DesignSystem
import SwiftUI
import WorkoutActivity

struct WorkoutIslandExpandedBody: View {
    private static let readyLineLimit = 2

    let content: WorkoutActivityContent
    let state: WorkoutActivityDisplayState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        return Group {
            switch state {
            case .set:
                setBody
            case let .rest(interval):
                restBody(interval: interval)
            case .restOver:
                restOverBody
            case .finishedSets:
                EmptyView()
            case let .timedSet(interval):
                restBody(interval: interval)
            case let .timedSetOver(endedAt):
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text("activity.timed.overtime")
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                    Text(endedAt, style: .timer)
                        .appStyle(Typography.numeralL)
                        .foregroundStyle(Palette.success)
                }
                .accessibilityElement(children: .combine)
            case let .timedSetRunning(startedAt):
                Text(startedAt, style: .timer)
                    .appStyle(Typography.numeralL)
            }
        }
        .foregroundStyle(Palette.textPrimary)
        .padding(.horizontal, Spacing.xs)
    }

    private var setBody: some View {
        return HStack(alignment: .bottom, spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(content.setText)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
                Text(content.loadText)
                    .appStyle(Typography.numeralL)
            }
            .lineLimit(1)
            .accessibilityElement(children: .combine)
            Spacer(minLength: Spacing.xs)
            if !content.plates.isEmpty {
                PlateStack(plates: plateItems)
                    .accessibilityHidden(true)
            }
        }
    }

    private func restBody(interval: ClosedRange<Date>) -> some View {
        return VStack(alignment: .leading, spacing: Spacing.s) {
            Text(timerInterval: interval, countsDown: true)
                .appStyle(Typography.numeralL)
            if !reduceMotion {
                WorkoutRestProgress(interval: interval, tint: Palette.accent)
            }
        }
    }

    private var restOverBody: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(content.readyText)
                .appStyle(Typography.title)
                .lineLimit(Self.readyLineLimit)
            if !content.loadText.isEmpty {
                Text(content.loadText)
                    .appStyle(Typography.numeralM)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var plateItems: [PlateStackItem] {
        return content.plates.map { plate in
            return PlateStackItem(rgb: plate.rgb, kilograms: plate.kilograms)
        }
    }
}
