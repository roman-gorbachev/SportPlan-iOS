import SwiftUI

struct WorkoutScreen: View {
    let onOpenSettings: () -> Void

    var body: some View {
        return StubContent(message: String(localized: "stub.workout"))
            .navigationTitle(AppTab.workout.title)
            .toolbar {
                return ToolbarItem(placement: .topBarTrailing) {
                    return Button(action: onOpenSettings) {
                        return Label(String(localized: "settings.title"), systemImage: "gearshape")
                    }
                }
            }
    }
}

#Preview {
    return NavigationStack {
        return WorkoutScreen(onOpenSettings: {})
    }
}
