import DesignSystem
import SwiftUI

struct HistoryEmptyContent: View {
    let onStartWorkout: () -> Void

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "history.empty.title"))
                .appStyle(Typography.title)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(String(localized: "history.empty.message"))
                .appStyle(Typography.body)
                .foregroundStyle(Palette.textSecondary)
            Button(action: onStartWorkout) {
                return Text(String(localized: "history.empty.action"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle())
            .padding(.top, Spacing.m)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.top, Spacing.xl)
    }
}
