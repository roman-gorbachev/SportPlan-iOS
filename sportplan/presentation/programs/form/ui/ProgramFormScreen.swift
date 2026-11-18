import DesignSystem
import SwiftUI

struct ProgramFormScreen: View {
    let data: ProgramFormUiData
    let onNameChange: @MainActor (String) -> Void
    let onDayLabelChange: @MainActor (String) -> Void
    let onDayNameChange: @MainActor (String) -> Void
    let onDismissSaveError: () -> Void

    var body: some View {
        return Form {
            Section {
                TextField(String(localized: "programForm.name.placeholder"), text: Binding(get: { return data.name }, set: onNameChange))
                    .foregroundStyle(Palette.textPrimary)
            } header: {
                ListSectionHeader(title: String(localized: "programForm.name"))
            }
            .appListRow()
            if data.isCreating {
                Section {
                    ProgramDayFields(
                        label: data.dayLabel,
                        name: data.dayName,
                        onLabelChange: onDayLabelChange,
                        onNameChange: onDayNameChange
                    )
                } header: {
                    ListSectionHeader(title: String(localized: "programForm.firstDay"))
                } footer: {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(String(localized: "programForm.firstDay.labelHint"))
                        Text(String(localized: "programForm.firstDay.moreDaysHint"))
                    }
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
                }
                .appListRow()
            }
        }
        .appStyle(Typography.body)
        .appGroupedList()
        .alert(
            String(localized: "common.error.title"),
            isPresented: Binding(get: { return data.isShowingSaveError }, set: { isPresented in
                if !isPresented {
                    onDismissSaveError()
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
    let data = ProgramFormUiData(isCreating: true, name: "Сила 3×", dayLabel: "A", dayName: "Грудь и трицепс", canSave: true, isShowingSaveError: false)
    return NavigationStack {
        return ProgramFormScreen(data: data, onNameChange: { _ in }, onDayLabelChange: { _ in }, onDayNameChange: { _ in }, onDismissSaveError: {})
            .navigationTitle(String(localized: "programForm.title.new"))
            .navigationBarTitleDisplayMode(.inline)
    }
}
