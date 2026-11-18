import DesignSystem
import Domain
import SwiftUI

struct ExercisePickerScreen: View {
    let data: ExercisePickerUiData
    let onSearchQueryChange: @MainActor (String) -> Void
    let onAdd: (UUID) -> Void
    let onCreate: () -> Void
    let onDismissError: () -> Void

    var body: some View {
        return Group {
            if data.isLibraryEmpty {
                EmptyStateView(
                    title: String(localized: "picker.empty.title"),
                    message: String(localized: "picker.empty.message"),
                    actionTitle: String(localized: "picker.new"),
                    action: onCreate
                )
            } else {
                exerciseList
                    .searchable(
                        text: Binding(get: { return data.searchQuery }, set: onSearchQueryChange),
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: Text(String(localized: "library.search"))
                    )
            }
        }
        .alert(
            String(localized: "common.error.title"),
            isPresented: Binding(get: { return data.isShowingError }, set: { isPresented in
                if !isPresented {
                    onDismissError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        } message: {
            Text(String(localized: "common.error.message"))
        }
    }

    private var exerciseList: some View {
        return List {
            Section {
            } footer: {
                Text(String(localized: "picker.hint"))
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            ForEach(data.sections) { section in
                return Section {
                    ForEach(section.exercises) { item in
                        return PickerExerciseRow(item: item) {
                            onAdd(item.id)
                        }
                    }
                } header: {
                    ListSectionHeader(title: section.title)
                }
                .appListRow()
            }
        }
        .appGroupedList()
        .overlay {
            if data.sections.isEmpty {
                ContentUnavailableView.search(text: data.searchQuery)
            }
        }
    }
}

#Preview {
    FontRegistry.registerFonts()
    let data = ExercisePickerUiData(
        sections: [
            PickerSectionItem(category: .freeWeight, title: "Свободный вес", exercises: [
                PickerExerciseItem(id: UUID(), name: "Жим лёжа", detail: "Олимпийский гриф", isInDay: true),
                PickerExerciseItem(id: UUID(), name: "Присед", detail: "Олимпийский гриф", isInDay: false),
            ]),
        ],
        isLibraryEmpty: false,
        searchQuery: "",
        isShowingError: false
    )
    return NavigationStack {
        return ExercisePickerScreen(data: data, onSearchQueryChange: { _ in }, onAdd: { _ in }, onCreate: {}, onDismissError: {})
            .navigationTitle("В день A")
            .navigationBarTitleDisplayMode(.inline)
    }
}
