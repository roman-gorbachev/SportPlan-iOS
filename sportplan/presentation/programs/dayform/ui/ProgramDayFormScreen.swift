import DesignSystem
import SwiftUI

struct ProgramDayFormScreen: View {
    let data: ProgramDayFormUiData
    let onLabelChange: @MainActor (String) -> Void
    let onNameChange: @MainActor (String) -> Void
    let onDelete: () -> Void
    let onConfirmDelete: () -> Void
    let onCancelDelete: () -> Void
    let onDismissError: () -> Void

    var body: some View {
        return Form {
            Section {
                ProgramDayFields(label: data.label, name: data.name, onLabelChange: onLabelChange, onNameChange: onNameChange)
            } header: {
                ListSectionHeader(title: data.programName)
            } footer: {
                Text(data.isNew ? String(localized: "programDay.form.newHint") : String(localized: "programDay.form.editHint"))
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            .appListRow()
            if !data.isNew {
                Section {
                    Button(String(localized: "programDay.delete"), role: .destructive, action: onDelete)
                        .foregroundStyle(Palette.destructive)
                        .frame(maxWidth: .infinity)
                }
                .appListRow()
            }
        }
        .appStyle(Typography.body)
        .appGroupedList()
        .dismissesKeyboard()
        .alert(
            String(localized: "programDay.delete.title \(data.originalName)"),
            isPresented: Binding(get: { return data.isConfirmingDelete }, set: { isPresented in
                if !isPresented {
                    onCancelDelete()
                }
            })
        ) {
            Button(String(localized: "programs.delete"), role: .destructive, action: onConfirmDelete)
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
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
}

#Preview {
    FontRegistry.registerFonts()
    let data = ProgramDayFormUiData(
        isNew: false,
        programName: "Сила 3×",
        label: "A",
        name: "Грудь и трицепс",
        originalName: "Грудь и трицепс",
        canSave: true,
        isConfirmingDelete: false,
        isShowingError: false
    )
    return NavigationStack {
        return ProgramDayFormScreen(
            data: data,
            onLabelChange: { _ in },
            onNameChange: { _ in },
            onDelete: {},
            onConfirmDelete: {},
            onCancelDelete: {},
            onDismissError: {}
        )
        .navigationTitle(String(localized: "programDay.form.title.edit"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
