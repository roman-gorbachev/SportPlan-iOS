import DesignSystem
import SwiftUI
import WorkoutActivity

struct WorkoutLockScreenView: View {
    private static let readyDotSize: CGFloat = 8
    private static let readyLineLimit = 2

    let startedAt: Date
    let content: WorkoutActivityContent
    let state: WorkoutActivityDisplayState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.s) {
            WorkoutElapsedText(startedAt: startedAt)
            details
        }
        .foregroundStyle(Palette.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }

    private var details: some View {
        return Group {
            switch state {
            case .set:
                setDetails
            case let .rest(interval):
                restDetails(interval: interval)
            case let .restOver(endedAt):
                restOverDetails(endedAt: endedAt)
            case .finishedSets:
                Text("activity.sets.done")
                    .appStyle(Typography.headline)
            case let .timedSet(interval):
                timedSetDetails(interval: interval)
            case let .timedSetOver(endedAt):
                timedSetOverDetails(endedAt: endedAt)
            case let .timedSetRunning(startedAt):
                timedSetRunningDetails(startedAt: startedAt)
            }
        }
    }

    private var setDetails: some View {
        return HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(content.exerciseName)
                    .appStyle(Typography.headline)
                Text(content.setText)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            .lineLimit(1)
            Spacer(minLength: Spacing.xs)
            Text(content.loadText)
                .appStyle(Typography.numeralM)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    private func restDetails(interval: ClosedRange<Date>) -> some View {
        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .bottom, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("activity.rest")
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                    Text(timerInterval: interval, countsDown: true)
                        .appStyle(Typography.numeralL)
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: Spacing.xs)
                if !content.loadText.isEmpty {
                    nextSet
                }
            }
            if !reduceMotion {
                WorkoutRestProgress(interval: interval, tint: Palette.ink)
            }
        }
    }

    private var nextSet: some View {
        return VStack(alignment: .trailing, spacing: Spacing.xxs) {
            Text("activity.next")
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
            Text(content.exerciseName)
                .appStyle(Typography.callout)
            Text(content.loadText)
                .appStyle(Typography.numeralS)
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }

    private func restOverDetails(endedAt: Date) -> some View {
        return HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(Palette.success)
                        .frame(width: Self.readyDotSize, height: Self.readyDotSize)
                        .accessibilityHidden(true)
                    Text("activity.rest.over")
                        .appStyle(Typography.headline)
                        .lineLimit(1)
                }
                Text(content.readyText)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(Self.readyLineLimit)
            }
            Spacer(minLength: Spacing.xs)
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("activity.rest.elapsed")
                    .appStyle(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
                Text(endedAt, style: .timer)
                    .appStyle(Typography.numeralM)
                    .multilineTextAlignment(.trailing)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var exerciseTitle: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(content.exerciseName)
                .appStyle(Typography.headline)
            Text(content.setText)
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
        }
        .lineLimit(1)
    }

    private func timedSetDetails(interval: ClosedRange<Date>) -> some View {
        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .bottom, spacing: Spacing.s) {
                exerciseTitle
                Spacer(minLength: Spacing.xs)
                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    Text("activity.timed.left")
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                    Text(timerInterval: interval, countsDown: true)
                        .appStyle(Typography.numeralL)
                        .multilineTextAlignment(.trailing)
                }
            }
            .accessibilityElement(children: .combine)
            if !reduceMotion {
                WorkoutRestProgress(interval: interval, tint: Palette.accent)
            }
        }
    }

    private func timedSetOverDetails(endedAt: Date) -> some View {
        return HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(Palette.success)
                        .frame(width: Self.readyDotSize, height: Self.readyDotSize)
                        .accessibilityHidden(true)
                    Text("activity.timed.over")
                        .appStyle(Typography.headline)
                        .lineLimit(1)
                }
                Text(content.exerciseName)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Spacing.xs)
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("activity.timed.overtime")
                    .appStyle(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
                Text(endedAt, style: .timer)
                    .appStyle(Typography.numeralM)
                    .foregroundStyle(Palette.success)
                    .multilineTextAlignment(.trailing)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func timedSetRunningDetails(startedAt: Date) -> some View {
        return HStack(spacing: Spacing.s) {
            exerciseTitle
            Spacer(minLength: Spacing.xs)
            Text(startedAt, style: .timer)
                .appStyle(Typography.numeralL)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
