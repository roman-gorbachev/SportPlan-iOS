import DesignSystem
import SwiftUI

@main
struct SportplanApp: App {
    @State private var container = AppDIContainer()

    init() {
        FontRegistry.registerFonts()
    }

    var body: some Scene {
        return WindowGroup {
            RootView(container: container)
        }
    }
}
