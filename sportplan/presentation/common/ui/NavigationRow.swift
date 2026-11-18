import DesignSystem
import SwiftUI

struct NavigationRow: View {
    let title: String
    let subtitle: String?
    let action: () -> Void

    var body: some View {
        return Button(action: action) {
            return HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .appStyle(Typography.body)
                        .foregroundStyle(Palette.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .appStyle(Typography.footnote)
                            .foregroundStyle(Palette.textSecondary)
                    }
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
