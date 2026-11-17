import DesignSystem
import SwiftUI

struct StubContent: View {
    let message: String

    var body: some View {
        return Text(message)
            .appStyle(Typography.body)
            .foregroundStyle(Palette.textSecondary)
            .multilineTextAlignment(.center)
            .padding(Spacing.emptyState)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.background)
    }
}
