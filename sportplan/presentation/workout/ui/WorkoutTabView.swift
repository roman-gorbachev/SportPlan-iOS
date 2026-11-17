import SwiftUI

struct WorkoutTabView: View {
    @Bindable var router: TabRouter

    var body: some View {
        return NavigationStack(path: $router.path) {
            return WorkoutScreen(onOpenSettings: { router.push(SettingsDestination()) })
                .navigationDestination(for: SettingsDestination.self) { _ in
                    return SettingsScreen()
                }
        }
    }
}
