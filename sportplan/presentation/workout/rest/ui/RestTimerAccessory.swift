import DesignSystem
import Domain
import SwiftUI

struct RestTimerAccessory: View {
    private static let minimumTapSize: CGFloat = 44
    private static let swipeMinimumDistance: CGFloat = 12
    private static let swipeSkipDistance: CGFloat = 72

    let data: RestTimerItem
    let onAdjust: (Int) -> Void
    let onSkip: () -> Void
    let onOpen: () -> Void

    @State private var swipeOffset: CGFloat = .zero
    @State private var swipeSkipCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        return HStack(spacing: Spacing.xs) {
            Menu {
                Button(action: onSkip) {
                    return Label(String(localized: "rest.menu.skip"), systemImage: "forward.end")
                }
                Button {
                    onAdjust(-RestPeriod.adjustmentStepSeconds)
                } label: {
                    return Label(String(localized: "rest.panel.shorten"), systemImage: "minus")
                }
                Button {
                    onAdjust(RestPeriod.adjustmentStepSeconds)
                } label: {
                    return Label(String(localized: "rest.panel.extend"), systemImage: "plus")
                }
                Button(action: onOpen) {
                    return Label(String(localized: "rest.menu.open"), systemImage: "dumbbell")
                }
            } label: {
                summary
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "rest.remaining.accessibility"))
            .accessibilityValue(Text(timerInterval: data.startedAt...data.endsAt, countsDown: true))
            .accessibilityHint(String(localized: "rest.menu.accessibility"))
            .accessibilityAddTraits(.isButton)
            Button {
                onAdjust(RestPeriod.adjustmentStepSeconds)
            } label: {
                return Text(String(localized: "rest.panel.extend"))
                    .appStyle(Typography.callout)
                    .foregroundStyle(Palette.textPrimary)
                    .frame(minWidth: Self.minimumTapSize, minHeight: Self.minimumTapSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "rest.panel.extend.accessibility"))
        }
        .padding(.leading, Spacing.m)
        .padding(.trailing, Spacing.xs)
        .offset(x: swipeOffset)
        .simultaneousGesture(swipeToSkip)
        .sensoryFeedback(.impact(weight: .medium), trigger: swipeSkipCount)
    }

    private var summary: some View {
        return HStack(spacing: Spacing.xs) {
            Image(systemName: "timer")
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)
            Text(timerInterval: data.startedAt...data.endsAt, countsDown: true)
                .appStyle(Typography.numeralS)
                .foregroundStyle(Palette.textPrimary)
            Text(data.nextText)
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
            Spacer(minLength: .zero)
        }
        .frame(minHeight: Self.minimumTapSize)
        .contentShape(Rectangle())
    }

    private var swipeToSkip: some Gesture {
        return DragGesture(minimumDistance: Self.swipeMinimumDistance)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else {
                    return
                }
                swipeOffset = reduceMotion ? .zero : value.translation.width
            }
            .onEnded { value in
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                if isHorizontal && abs(value.translation.width) >= Self.swipeSkipDistance {
                    swipeSkipCount += 1
                    onSkip()
                }
                withAnimation(reduceMotion ? nil : .snappy) {
                    swipeOffset = .zero
                }
            }
    }
}

#Preview {
    FontRegistry.registerFonts()
    let start = Date().addingTimeInterval(-15)
    return RestTimerAccessory(
        data: RestTimerItem(
            startedAt: start,
            endsAt: start.addingTimeInterval(120),
            title: "Отдых после подхода 3",
            totalText: "из 2:00",
            nextText: "отдых · дальше 65 × 8"
        ),
        onAdjust: { _ in },
        onSkip: {},
        onOpen: {}
    )
}
