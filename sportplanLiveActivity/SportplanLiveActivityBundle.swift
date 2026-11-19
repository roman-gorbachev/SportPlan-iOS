import DesignSystem
import SwiftUI
import WidgetKit

@main
struct SportplanLiveActivityBundle: WidgetBundle {
    init() {
        FontRegistry.registerFonts()
    }

    var body: some Widget {
        return WorkoutLiveActivity()
    }
}
