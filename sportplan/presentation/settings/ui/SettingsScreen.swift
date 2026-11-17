import SwiftUI

struct SettingsScreen: View {
    var body: some View {
        return StubContent(message: String(localized: "stub.settings"))
            .navigationTitle(String(localized: "settings.title"))
    }
}

#Preview {
    return NavigationStack {
        return SettingsScreen()
    }
}
