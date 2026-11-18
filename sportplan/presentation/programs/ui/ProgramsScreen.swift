import DesignSystem
import SwiftUI

struct ProgramsScreen: View {
    let data: ProgramsUiData
    let onOpenLibrary: () -> Void

    var body: some View {
        return List {
            Section {
                NavigationRow(title: String(localized: "programs.library.title"), subtitle: exerciseSummary, action: onOpenLibrary)
                    .appListRow()
            } footer: {
                Text(String(localized: "stub.programs"))
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .appGroupedList()
    }

    private var exerciseSummary: String {
        guard data.exerciseCount > 0 else {
            return String(localized: "programs.library.empty")
        }
        return String(localized: "programs.library.count \(data.exerciseCount)")
    }
}

#Preview {
    FontRegistry.registerFonts()
    return NavigationStack {
        return ProgramsScreen(data: ProgramsUiData(exerciseCount: 12), onOpenLibrary: {})
            .navigationTitle(AppTab.programs.title)
    }
}
