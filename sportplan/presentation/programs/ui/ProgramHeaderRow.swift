import DesignSystem
import SwiftUI

struct ProgramHeaderRow: View {
    private static let menuButtonSize: CGFloat = 44

    let program: ProgramItem
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        return HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(program.name)
                    .appStyle(Typography.title)
                    .foregroundStyle(Palette.textPrimary)
                Text(program.summary)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.s)
            Menu {
                Button(String(localized: "programs.rename"), systemImage: "pencil", action: onRename)
                Button(String(localized: "programs.delete"), systemImage: "trash", role: .destructive, action: onDelete)
            } label: {
                return Image(systemName: "ellipsis")
                    .appStyle(Typography.headline)
                    .foregroundStyle(Palette.textSecondary)
                    .frame(width: Self.menuButtonSize, height: Self.menuButtonSize)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "programs.actions \(program.name)"))
        }
    }
}
