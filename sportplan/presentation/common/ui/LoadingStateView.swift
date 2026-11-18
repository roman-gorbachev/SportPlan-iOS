import DesignSystem
import SwiftUI

struct LoadingStateView: View {
    var body: some View {
        return ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.background)
    }
}
