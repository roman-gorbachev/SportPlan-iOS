import SwiftUI

struct ProgramsScreen: View {
    var body: some View {
        return StubContent(message: String(localized: "stub.programs"))
            .navigationTitle(AppTab.programs.title)
    }
}

#Preview {
    return NavigationStack {
        return ProgramsScreen()
    }
}
