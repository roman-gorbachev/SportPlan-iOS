import DesignSystem
import SwiftUI

struct ErrorStateView: View {
    var body: some View {
        return EmptyStateView(
            title: String(localized: "common.error.title"),
            message: String(localized: "common.error.message")
        )
    }
}
