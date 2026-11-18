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
                    message: data.emptyMessage,
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
                Text(data.hint)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            ForEach(data.sections) { section in
                return Section {
                    ForEach(section.exercises) { item in
                        return PickerExerciseRow(item: item, addedLabel: data.addedLabel) {
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
                PickerExerciseItem(id: UUID(), name: "Жим лёжа", detail: "Олимпийский гриф", isAdded: true, accessibilityLabel: "«Жим лёжа» уже в дне"),
                PickerExerciseItem(id: UUID(), name: "Присед", detail: "Олимпийский гриф", isAdded: false, accessibilityLabel: "Добавить «Присед» в день"),
            ]),
        ],
        isLibraryEmpty: false,
        searchQuery: "",
        hint: "Тап — упражнение сразу встанет в день с целью 3 × 8–12 и своим отдыхом. Уже добавленные отмечены.",
        emptyMessage: "Создай первое упражнение — оно сразу встанет в день.",
        addedLabel: "в дне",
        isShowingError: false
    )
    return NavigationStack {
        return ExercisePickerScreen(data: data, onSearchQueryChange: { _ in }, onAdd: { _ in }, onCreate: {}, onDismissError: {})
            .navigationTitle("В день A")
            .navigationBarTitleDisplayMode(.inline)
    }
}
