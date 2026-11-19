import DesignSystem
import SwiftUI

struct SetRow: View {
    private static let numberSize: CGFloat = 28
    private static let minimumHeight: CGFloat = 88
    private static let runningDotSize: CGFloat = 7
    private static let chipHorizontalPadding: CGFloat = 7
    private static let chipVerticalPadding: CGFloat = 1
    private static let chipBorderWidth: CGFloat = 1
    private static let valueSpacing: CGFloat = 5
    private static let lineSpacing: CGFloat = 6
    private static let valueMinimumScaleFactor: CGFloat = 0.5

    let row: SetRowItem
    let onEdit: () -> Void
    let onAction: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            mainLine
            if dynamicTypeSize.isAccessibilitySize, let plates = row.plates {
                platesView(plates)
                    .padding(.leading, Self.numberSize + Spacing.s)
            }
        }
        .frame(minHeight: Self.minimumHeight)
        .sensoryFeedback(.success, trigger: row.state == .completed) { _, isCompleted in
            return isCompleted
        }
    }

    private var mainLine: some View {
        return HStack(spacing: Spacing.s) {
            Button(action: onEdit) {
                return HStack(spacing: Spacing.s) {
                    numberBadge
                    VStack(alignment: .leading, spacing: Self.lineSpacing) {
                        valueLine
                        detailLine
                    }
                    Spacer(minLength: Spacing.xs)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!row.isEditable)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(row.isEditable ? String(localized: "workout.set.edit.hint") : "")
            if !dynamicTypeSize.isAccessibilitySize, let plates = row.plates {
                platesView(plates)
            }
            SetActionButton(state: row.state, isTimed: row.isTimed, action: onAction)
        }
    }

    private func platesView(_ plates: SetRowPlates) -> some View {
        return HStack(spacing: Spacing.xxs) {
            PlateStack(plates: plates.plates)
            if let remainder = plates.remainder {
                Text(remainder)
                    .appStyle(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(plates.accessibilityLabel)
    }

    private var numeralColor: Color {
        switch row.state {
        case .planned:
            return Palette.textSecondary
        case .current:
            return row.isTimed ? Palette.textSecondary : Palette.textPrimary
        case .running, .completed:
            return Palette.textPrimary
        }
    }

    private var isHighlighted: Bool {
        return row.state == .current || row.state == .running
    }

    private var numberBadge: some View {
        return Text(row.number.formatted())
            .appStyle(Typography.caption)
            .foregroundStyle(isHighlighted ? Palette.onInk : Palette.textSecondary)
            .frame(width: Self.numberSize, height: Self.numberSize)
            .background {
                if isHighlighted {
                    Circle()
                        .fill(Palette.ink)
                }
            }
    }

    @ViewBuilder
    private var valueLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.valueSpacing) {
            switch row.value {
            case let .weightReps(weight, reps):
                weightReps(weight: weight, reps: reps)
            case let .bodyweightReps(addedWeight, reps):
                if let addedWeight {
                    weightReps(weight: addedWeight, reps: reps)
                } else {
                    numeral(reps, style: Typography.numeralL)
                    unit(String(localized: "workout.set.repsUnit"))
                }
            case let .duration(text, runningSince):
                if let runningSince {
                    Text(runningSince, style: .timer)
                        .appStyle(Typography.numeralL)
                        .foregroundStyle(Palette.textPrimary)
                } else {
                    numeral(text, style: Typography.numeralL)
                }
                unit(String(localized: "workout.set.minutes"))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(Self.valueMinimumScaleFactor)
    }

    @ViewBuilder
    private func weightReps(weight: String, reps: String) -> some View {
        numeral(weight, style: Typography.numeralL)
        unit(String(localized: "workout.set.kg"))
        Text(String(localized: "workout.set.times"))
            .appStyle(Typography.headline)
            .foregroundStyle(Palette.textSecondary)
        numeral(reps, style: Typography.numeralM)
    }

    private func numeral(_ text: String, style: TypeStyle) -> some View {
        return Text(text)
            .appStyle(style)
            .foregroundStyle(numeralColor)
    }

    private func unit(_ text: String) -> some View {
        return Text(text)
            .appStyle(Typography.footnote)
            .foregroundStyle(Palette.textSecondary)
    }

    @ViewBuilder
    private var detailLine: some View {
        if row.isWarmup || row.caption != nil {
            HStack(spacing: Spacing.xs) {
                if row.isWarmup {
                    Text(String(localized: "workout.set.warmup"))
                        .appStyle(Typography.caption)
                        .foregroundStyle(Palette.warmup)
                        .padding(.horizontal, Self.chipHorizontalPadding)
                        .padding(.vertical, Self.chipVerticalPadding)
                        .overlay {
                            RoundedRectangle(cornerRadius: CornerRadius.chip)
                                .strokeBorder(Palette.separatorStrong, lineWidth: Self.chipBorderWidth)
                        }
                }
                if row.state == .running {
                    Circle()
                        .fill(Palette.accent)
                        .frame(width: Self.runningDotSize, height: Self.runningDotSize)
                }
                if let caption = row.caption {
                    Text(caption)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
    }

    private var accessibilityLabel: String {
        var parts = [String(localized: "workout.set.number \(row.number)")]
        if row.isWarmup {
            parts.append(String(localized: "workout.set.warmup"))
        }
        parts.append(row.valueAccessibility)
        if let caption = row.caption {
            parts.append(caption)
        }
        return parts.joined(separator: String(localized: "format.listSeparator"))
    }
}
