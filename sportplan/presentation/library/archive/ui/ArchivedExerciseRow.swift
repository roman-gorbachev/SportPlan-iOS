import DesignSystem
import SwiftUI

struct ArchivedExerciseRow: View {
    let item: ArchivedExerciseItem
    let onRestore: () -> Void

    var body: some View {
        return HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.name)
                    .appStyle(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                Text(item.detail)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: Spacing.s)
            Button(String(localized: "archive.restore"), action: onRestore)
                .buttonStyle(SunkenButtonStyle())
                .fixedSize()
                .accessibilityLabel(item.restoreAccessibilityLabel)
        }
    }
}
