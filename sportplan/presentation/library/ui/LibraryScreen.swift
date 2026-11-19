import DesignSystem
import Domain
import SwiftUI

struct LibraryScreen: View {
    let data: LibraryUiData
    let onSearchQueryChange: @MainActor (String) -> Void
    let onQuickAdd: (QuickExercise) -> Void
    let onAddCustom: () -> Void
    let onArchive: (UUID) -> Void
    let onConfirmArchive: (UUID) -> Void
    let onCancelArchive: () -> Void
    let onDismissArchiveError: () -> Void

    var body: some View {
        return Group {
            if data.isLibraryEmpty {
                LibraryEmptyContent(onQuickAdd: onQuickAdd, onAddCustom: onAddCustom)
            } else {
                exerciseList
                    .searchable(
                        text: Binding(get: { return data.searchQuery }, set: onSearchQueryChange),
                        prompt: Text(String(localized: "library.search"))
                    )
            }
        }
        .alert(
            String(localized: "library.archive.error"),
            isPresented: Binding(get: { return data.isShowingArchiveError }, set: { isPresented in
                if !isPresented {
                    onDismissArchiveError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        }
    }

    private var exerciseList: some View {
        return List {
            ForEach(data.sections) { section in
                return Section {
                    ForEach(section.exercises) { item in
                        return LibraryExerciseRow(item: item)
                            .swipeActions(edge: .trailing) {
                                DestructiveSwipeButton(title: String(localized: "library.archive"), systemImage: "archivebox") {
                                    onArchive(item.id)
                                }
                            }
                            .confirmationDialog(
                                archiveTitle,
                                isPresented: isConfirmingArchive(of: item.id),
                                titleVisibility: .visible,
                                presenting: data.pendingArchive
                            ) { confirmation in
                                Button(String(localized: "library.archive"), role: .destructive) {
                                    onConfirmArchive(confirmation.exerciseId)
                                }
                                Button(String(localized: "common.cancel"), role: .cancel) {}
                            } message: { confirmation in
                                Text(archiveMessage(confirmation))
                            }
                            .appListRow()
                    }
                } header: {
                    ListSectionHeader(title: section.title)
                }
            }
        }
        .appGroupedList()
        .overlay {
            if data.sections.isEmpty {
                ContentUnavailableView.search(text: data.searchQuery)
            }
        }
    }

    private func isConfirmingArchive(of id: UUID) -> Binding<Bool> {
        return Binding(get: { return data.pendingArchive?.exerciseId == id }, set: { isPresented in
            if !isPresented {
                onCancelArchive()
            }
        })
    }

    private var archiveTitle: String {
        guard let pendingArchive = data.pendingArchive else {
            return ""
        }
        return String(localized: "library.archive.title \(pendingArchive.exerciseName)")
    }

    private func archiveMessage(_ confirmation: LibraryArchiveConfirmation) -> String {
        guard confirmation.programDayCount > 0 else {
            return String(localized: "library.archive.message.unused")
        }
        return String(localized: "library.archive.message.days \(confirmation.programDayCount)")
    }
}

#Preview("Data") {
    FontRegistry.registerFonts()
    let sections = [
        LibrarySectionItem(category: .freeWeight, title: "Свободный вес", exercises: [
            LibraryExerciseItem(id: UUID(), name: "Жим лёжа", detail: "Олимпийский гриф · повторы"),
            LibraryExerciseItem(id: UUID(), name: "Жим гантелей на наклонной", detail: "Гантели · повторы"),
        ]),
        LibrarySectionItem(category: .bodyweight, title: "Собственный вес", exercises: [
            LibraryExerciseItem(id: UUID(), name: "Планка", detail: "время"),
        ]),
    ]
    let data = LibraryUiData(sections: sections, isLibraryEmpty: false, searchQuery: "", pendingArchive: nil, isShowingArchiveError: false)
    return NavigationStack {
        return LibraryScreen(
            data: data,
            onSearchQueryChange: { _ in },
            onQuickAdd: { _ in },
            onAddCustom: {},
            onArchive: { _ in },
            onConfirmArchive: { _ in },
            onCancelArchive: {},
            onDismissArchiveError: {}
        )
        .navigationTitle(String(localized: "library.title"))
    }
}

#Preview("Empty") {
    FontRegistry.registerFonts()
    let data = LibraryUiData(sections: [], isLibraryEmpty: true, searchQuery: "", pendingArchive: nil, isShowingArchiveError: false)
    return NavigationStack {
        return LibraryScreen(
            data: data,
            onSearchQueryChange: { _ in },
            onQuickAdd: { _ in },
            onAddCustom: {},
            onArchive: { _ in },
            onConfirmArchive: { _ in },
            onCancelArchive: {},
            onDismissArchiveError: {}
        )
        .navigationTitle(String(localized: "library.title"))
    }
}
