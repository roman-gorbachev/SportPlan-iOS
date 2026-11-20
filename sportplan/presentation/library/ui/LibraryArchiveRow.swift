import DesignSystem
import SwiftUI

struct LibraryArchiveRow: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        return Button(action: action) {
            return HStack(spacing: Spacing.s) {
                Text(String(localized: "library.archive.row"))
                    .appStyle(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                Spacer(minLength: Spacing.s)
                Text(count, format: .number)
                    .appStyle(Typography.numeralS)
                    .foregroundStyle(Palette.textSecondary)
                Image(systemName: "chevron.right")
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textTertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
