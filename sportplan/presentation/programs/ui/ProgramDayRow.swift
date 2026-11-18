import DesignSystem
import SwiftUI

struct ProgramDayRow: View {
    let day: ProgramDayItem
    let action: () -> Void

    var body: some View {
        return Button(action: action) {
            return HStack(spacing: Spacing.s) {
                if let label = day.label {
                    ProgramDayLabelBadge(label: label)
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(day.name)
                        .appStyle(Typography.body)
                        .foregroundStyle(Palette.textPrimary)
                    Text(day.summary)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer(minLength: Spacing.s)
                Image(systemName: "chevron.right")
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textTertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
