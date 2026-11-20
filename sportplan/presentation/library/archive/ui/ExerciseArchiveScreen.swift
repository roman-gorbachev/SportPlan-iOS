import DesignSystem
import SwiftUI

struct ExerciseArchiveScreen: View {
    let data: ExerciseArchiveUiData
    let onRestore: (UUID) -> Void
    let onDismissRestoreError: () -> Void

    var body: some View {
        return List {
            Section {
                ForEach(data.items) { item in
                    return ArchivedExerciseRow(item: item) {
                        onRestore(item.id)
                    }
                }
            } header: {
                Text(String(localized: "archive.caption"))
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
                    .textCase(nil)
            } footer: {
                Text(String(localized: "archive.footer"))
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .appGroupedList()
        .navigationTitle(String(localized: "archive.title"))
        .alert(
            String(localized: "archive.restore.error"),
            isPresented: Binding(get: { return data.isShowingRestoreError }, set: { isPresented in
                if !isPresented {
                    onDismissRestoreError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        }
    }
}

#Preview {
    FontRegistry.registerFonts()
    let data = ExerciseArchiveUiData(
        items: [
            ArchivedExerciseItem(id: UUID(), name: "Жим Арнольда", detail: "Гантели · 6 тренировок", restoreAccessibilityLabel: ""),
            ArchivedExerciseItem(id: UUID(), name: "Тяга Т-грифа", detail: "Тренажёр с блинами · 3 тренировки", restoreAccessibilityLabel: ""),
        ],
        isShowingRestoreError: false
    )
    return NavigationStack {
        return ExerciseArchiveScreen(data: data, onRestore: { _ in }, onDismissRestoreError: {})
    }
}
