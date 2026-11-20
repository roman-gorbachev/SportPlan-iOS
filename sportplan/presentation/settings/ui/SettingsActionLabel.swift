import DesignSystem
import SwiftUI

struct SettingsActionLabel: View {
    private static let minimumHeight: CGFloat = 44

    let title: String
    let systemImage: String
    let isEnabled: Bool

    var body: some View {
        return HStack(spacing: Spacing.s) {
            Image(systemName: systemImage)
                .accessibilityHidden(true)
            Text(title)
            Spacer(minLength: 0)
        }
        .appStyle(Typography.body)
        .foregroundStyle(isEnabled ? Palette.accent : Palette.textTertiary)
        .frame(minHeight: Self.minimumHeight)
        .contentShape(Rectangle())
    }
}
