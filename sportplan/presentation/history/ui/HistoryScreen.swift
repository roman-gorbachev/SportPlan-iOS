import SwiftUI

struct HistoryScreen: View {
    var body: some View {
        return StubContent(message: String(localized: "stub.history"))
            .navigationTitle(AppTab.history.title)
    }
}

#Preview {
    return NavigationStack {
        return HistoryScreen()
    }
}
