import DesignSystem
import SwiftUI

struct RestTimerAccessory: View {
    private static let minimumTapSize: CGFloat = 44

    let data: RestTimerItem
    let onExtend: () -> Void
    let onOpen: () -> Void

    var body: some View {
        return HStack(spacing: Spacing.xs) {
            Button(action: onOpen) {
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
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "rest.remaining.accessibility"))
            .accessibilityValue(Text(timerInterval: data.startedAt...data.endsAt, countsDown: true))
            .accessibilityHint(String(localized: "rest.accessory.open.accessibility"))
            .accessibilityAddTraits(.isButton)
            Button(action: onExtend) {
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
        onExtend: {},
        onOpen: {}
    )
}
