import SwiftUI

struct ProgramsTabView: View {
    @Bindable var router: TabRouter

    var body: some View {
        return NavigationStack(path: $router.path) {
            return ProgramsScreen()
        }
    }
}
