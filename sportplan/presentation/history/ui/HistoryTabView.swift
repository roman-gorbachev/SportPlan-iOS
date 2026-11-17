import SwiftUI

struct HistoryTabView: View {
    @Bindable var router: TabRouter

    var body: some View {
        return NavigationStack(path: $router.path) {
            return HistoryScreen()
        }
    }
}
