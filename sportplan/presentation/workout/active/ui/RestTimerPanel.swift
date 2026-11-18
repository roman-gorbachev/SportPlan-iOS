import DesignSystem
import Domain
import SwiftUI

struct RestTimerPanel: View {
    let data: RestTimerItem
    let onAdjust: (Int) -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text(data.title)
                Spacer(minLength: Spacing.xs)
                Text(data.totalText)
            }
            .appStyle(Typography.footnote)
            .foregroundStyle(Palette.textSecondary)
            Text(timerInterval: data.startedAt...data.endsAt, countsDown: true)
                .appStyle(Typography.numeralHero)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityLabel(String(localized: "rest.remaining.accessibility"))
                .accessibilityValue(Text(timerInterval: data.startedAt...data.endsAt, countsDown: true))
            if !reduceMotion {
                ProgressView(timerInterval: data.startedAt...data.endsAt, countsDown: false) {
                    return EmptyView()
                } currentValueLabel: {
                    return EmptyView()
                }
                .tint(Palette.ink)
                .accessibilityHidden(true)
            }
            HStack(spacing: Spacing.xs) {
                panelButton(
                    title: String(localized: "rest.panel.shorten"),
                    accessibilityLabel: String(localized: "rest.panel.shorten.accessibility")
                ) {
                    onAdjust(-RestPeriod.adjustmentStepSeconds)
                }
                panelButton(
                    title: String(localized: "rest.panel.extend"),
                    accessibilityLabel: String(localized: "rest.panel.extend.accessibility")
                ) {
                    onAdjust(RestPeriod.adjustmentStepSeconds)
                }
                Button(action: onSkip) {
                    return Text(String(localized: "rest.panel.skip"))
                        .lineLimit(1)
                        .fixedSize()
                }
                .buttonStyle(SunkenButtonStyle())
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private func panelButton(title: String, accessibilityLabel: String?, action: @escaping () -> Void) -> some View {
        return Button(action: action) {
            return Text(title)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SunkenButtonStyle())
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

#Preview {
    FontRegistry.registerFonts()
    let start = Date().addingTimeInterval(-15)
    return List {
        RestTimerPanel(
            data: RestTimerItem(
                startedAt: start,
                endsAt: start.addingTimeInterval(120),
                title: "Отдых после подхода 3",
                totalText: "из 2:00",
                nextText: "отдых · дальше 65 × 8"
            ),
            onAdjust: { _ in },
            onSkip: {}
        )
    }
    .appGroupedList()
}
