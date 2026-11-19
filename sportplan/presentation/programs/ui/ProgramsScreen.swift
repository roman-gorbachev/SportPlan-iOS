import DesignSystem
import SwiftUI

struct ProgramsScreen: View {
    let data: ProgramsUiData
    let onOpenLibrary: () -> Void
    let onCreateProgram: () -> Void
    let onRenameProgram: (ProgramItem) -> Void
    let onDeleteProgram: (UUID) -> Void
    let onConfirmDelete: (UUID) -> Void
    let onCancelDelete: () -> Void
    let onDeleteDay: (UUID) -> Void
    let onConfirmDeleteDay: (UUID) -> Void
    let onCancelDeleteDay: () -> Void
    let onOpenDay: (UUID) -> Void
    let onAddDay: (ProgramItem) -> Void
    let onDismissError: () -> Void

    var body: some View {
        return List {
            Section {
                NavigationRow(title: String(localized: "programs.library.title"), subtitle: exerciseSummary, action: onOpenLibrary)
                    .appPlainRow()
            }
            if data.programs.isEmpty {
                Section {
                    EmptyStateView(
                        title: String(localized: "programs.empty.title"),
                        message: String(localized: "programs.empty.message"),
                        actionTitle: String(localized: "programs.create"),
                        action: onCreateProgram
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            } else {
                ForEach(data.programs) { program in
                    return programSection(program)
                }
            }
        }
        .appPlainList()
        .alert(
            deletionTitle,
            isPresented: Binding(get: { return data.pendingDeletion != nil }, set: { isPresented in
                if !isPresented {
                    onCancelDelete()
                }
            }),
            presenting: data.pendingDeletion
        ) { confirmation in
            Button(String(localized: "programs.delete"), role: .destructive) {
                onConfirmDelete(confirmation.programId)
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: { _ in
            Text(String(localized: "programs.delete.message"))
        }
        .alert(
            dayDeletionTitle,
            isPresented: Binding(get: { return data.pendingDayDeletion != nil }, set: { isPresented in
                if !isPresented {
                    onCancelDeleteDay()
                }
            }),
            presenting: data.pendingDayDeletion
        ) { confirmation in
            Button(String(localized: "programs.delete"), role: .destructive) {
                onConfirmDeleteDay(confirmation.dayId)
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: { _ in
            Text(String(localized: "programDay.delete.message"))
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

    private func programSection(_ program: ProgramItem) -> some View {
        return Section {
            ProgramHeaderRow(
                program: program,
                onRename: { onRenameProgram(program) },
                onDelete: { onDeleteProgram(program.id) }
            )
            .swipeActions(edge: .trailing) {
                DestructiveSwipeButton(title: String(localized: "programs.delete")) {
                    onDeleteProgram(program.id)
                }
            }
            if program.days.isEmpty {
                Text(String(localized: "programs.days.empty"))
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            ForEach(program.days) { day in
                return ProgramDayRow(day: day) {
                    onOpenDay(day.id)
                }
                .swipeActions(edge: .trailing) {
                    DestructiveSwipeButton(title: String(localized: "programDay.delete")) {
                        onDeleteDay(day.id)
                    }
                }
            }
            Button {
                onAddDay(program)
            } label: {
                return Label(String(localized: "programs.day.add"), systemImage: "plus")
                    .appStyle(Typography.callout)
            }
            .foregroundStyle(Palette.accent)
        }
        .appPlainRow()
    }

    private var exerciseSummary: String {
        guard data.exerciseCount > 0 else {
            return String(localized: "programs.library.empty")
        }
        return String(localized: "programs.library.count \(data.exerciseCount)")
    }

    private var dayDeletionTitle: String {
        guard let pendingDayDeletion = data.pendingDayDeletion else {
            return ""
        }
        return String(localized: "programDay.delete.title \(pendingDayDeletion.dayName)")
    }

    private var deletionTitle: String {
        guard let pendingDeletion = data.pendingDeletion else {
            return ""
        }
        return String(localized: "programs.delete.title \(pendingDeletion.programName)")
    }
}

#Preview("Data") {
    FontRegistry.registerFonts()
    let programs = [
        ProgramItem(id: UUID(), name: "Сила 3×", summary: "3 дня", days: [
            ProgramDayItem(id: UUID(), label: "A", name: "Грудь и трицепс", summary: "5 упражнений"),
            ProgramDayItem(id: UUID(), label: "B", name: "Спина и бицепс", summary: "6 упражнений"),
        ]),
        ProgramItem(id: UUID(), name: "Разгрузка", summary: "нет дней", days: []),
    ]
    let data = ProgramsUiData(exerciseCount: 24, programs: programs, pendingDeletion: nil, pendingDayDeletion: nil, isShowingError: false)
    return NavigationStack {
        return ProgramsScreen(
            data: data,
            onOpenLibrary: {},
            onCreateProgram: {},
            onRenameProgram: { _ in },
            onDeleteProgram: { _ in },
            onConfirmDelete: { _ in },
            onCancelDelete: {},
            onDeleteDay: { _ in },
            onConfirmDeleteDay: { _ in },
            onCancelDeleteDay: {},
            onOpenDay: { _ in },
            onAddDay: { _ in },
            onDismissError: {}
        )
        .navigationTitle(AppTab.programs.title)
    }
}

#Preview("Empty") {
    FontRegistry.registerFonts()
    let data = ProgramsUiData(exerciseCount: 0, programs: [], pendingDeletion: nil, pendingDayDeletion: nil, isShowingError: false)
    return NavigationStack {
        return ProgramsScreen(
            data: data,
            onOpenLibrary: {},
            onCreateProgram: {},
            onRenameProgram: { _ in },
            onDeleteProgram: { _ in },
            onConfirmDelete: { _ in },
            onCancelDelete: {},
            onDeleteDay: { _ in },
            onConfirmDeleteDay: { _ in },
            onCancelDeleteDay: {},
            onOpenDay: { _ in },
            onAddDay: { _ in },
            onDismissError: {}
        )
        .navigationTitle(AppTab.programs.title)
    }
}
