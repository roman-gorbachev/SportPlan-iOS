import DesignSystem
import Domain
import SwiftUI

struct AddExerciseTypeScreen: View {
    let onSelect: (ExerciseLoadKind) -> Void

    var body: some View {
        return List {
            Section {
                EmptyView()
            } header: {
                Text(String(localized: "addExercise.type.question"))
                    .appStyle(Typography.title)
                    .foregroundStyle(Palette.textPrimary)
                    .textCase(nil)
                    .accessibilityAddTraits(.isHeader)
            }
            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                return Section {
                    ForEach(category.loadKinds, id: \.self) { loadKind in
                        return NavigationRow(title: loadKind.title, subtitle: loadKind.examples) {
                            onSelect(loadKind)
                        }
                        .appListRow()
                    }
                } header: {
                    ListSectionHeader(title: category.loadKindGroupTitle)
                }
            }
        }
        .appGroupedList()
    }
}

#Preview {
    FontRegistry.registerFonts()
    return NavigationStack {
        return AddExerciseTypeScreen(onSelect: { _ in })
            .navigationTitle(String(localized: "addExercise.title"))
            .navigationBarTitleDisplayMode(.inline)
    }
}
