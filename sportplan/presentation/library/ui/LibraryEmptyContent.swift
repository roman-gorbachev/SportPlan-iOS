import DesignSystem
import Domain
import SwiftUI

struct LibraryEmptyContent: View {
    let onQuickAdd: (QuickExercise) -> Void
    let onAddCustom: () -> Void

    var body: some View {
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(String(localized: "library.empty.title"))
                        .appStyle(Typography.title)
                        .foregroundStyle(Palette.textPrimary)
                    Text(String(localized: "library.empty.message"))
                        .appStyle(Typography.callout)
                        .foregroundStyle(Palette.textSecondary)
                }
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(QuickExercise.allCases, id: \.self) { quickExercise in
                        return Button(quickExercise.title) {
                            onQuickAdd(quickExercise)
                        }
                        .buttonStyle(ChipButtonStyle())
                    }
                }
                Button(action: onAddCustom) {
                    return Text(String(localized: "library.empty.custom"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(InkButtonStyle())
                .padding(.top, Spacing.xs)
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.xxl)
        }
        .background(Palette.background)
    }
}
