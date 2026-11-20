import DesignSystem
import Domain
import SwiftUI

struct EquipmentEditorScreen: View {
    let data: EquipmentEditorUiData
    let onNameChange: @MainActor (String) -> Void
    let onKindChange: @MainActor (EquipmentKind) -> Void
    let onBaseWeightChange: @MainActor (String) -> Void
    let onWeightStepChange: @MainActor (String) -> Void
    let onArchive: () -> Void
    let onDismissSaveError: () -> Void

    @State private var isConfirmingArchive = false

    var body: some View {
        return Form {
            Section {
                TextField(String(localized: "equipment.editor.name"), text: Binding(get: { return data.name }, set: onNameChange))
                    .foregroundStyle(Palette.textPrimary)
                if data.isKindLocked {
                    LabeledContent(String(localized: "equipment.editor.kind"), value: data.kind.title)
                        .foregroundStyle(Palette.textPrimary)
                } else {
                    Picker(String(localized: "equipment.editor.kind"), selection: Binding(get: { return data.kind }, set: onKindChange)) {
                        return ForEach(EquipmentKind.allCases, id: \.self) { kind in
                            return Text(kind.title).tag(kind)
                        }
                    }
                }
            } footer: {
                if data.exerciseCount > 0 {
                    Text(String(localized: "equipment.editor.usage \(data.exerciseCount)"))
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .appListRow()
            Section {
                if data.kind.hasBaseWeight {
                    weightField(title: data.kind.baseWeightTitle, text: data.baseWeightText, onChange: onBaseWeightChange)
                }
                weightField(title: String(localized: "equipment.editor.weightStep"), text: data.weightStepText, onChange: onWeightStepChange)
            }
            .appListRow()
            if data.isExisting {
                Section {
                    Button(String(localized: "equipment.editor.archive"), role: .destructive) {
                        isConfirmingArchive = true
                    }
                    .foregroundStyle(Palette.destructive)
                }
                .appListRow()
            }
        }
        .appStyle(Typography.body)
        .appGroupedList()
        .dismissesKeyboard()
        .confirmationDialog(
            String(localized: "equipment.editor.archive.title \(data.name)"),
            isPresented: $isConfirmingArchive,
            titleVisibility: .visible
        ) {
            Button(String(localized: "equipment.editor.archive"), role: .destructive, action: onArchive)
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "equipment.editor.archive.message"))
        }
        .alert(
            String(localized: "equipment.editor.saveError"),
            isPresented: Binding(get: { return data.isShowingSaveError }, set: { isPresented in
                if !isPresented {
                    onDismissSaveError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        }
    }

    private func weightField(title: String, text: String, onChange: @escaping @MainActor (String) -> Void) -> some View {
        return LabeledContent(title) {
            return TextField(title, text: Binding(get: { return text }, set: onChange))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .appStyle(Typography.numeralS)
                .foregroundStyle(Palette.textPrimary)
        }
        .foregroundStyle(Palette.textPrimary)
    }
}

#Preview {
    FontRegistry.registerFonts()
    let data = EquipmentEditorUiData(
        name: "Олимпийский гриф",
        kind: .barbell,
        baseWeightText: "20",
        weightStepText: "2,5",
        isExisting: true,
        isKindLocked: true,
        exerciseCount: 4,
        canSave: true,
        isSaving: false,
        isShowingSaveError: false
    )
    return NavigationStack {
        return EquipmentEditorScreen(
            data: data,
            onNameChange: { _ in },
            onKindChange: { _ in },
            onBaseWeightChange: { _ in },
            onWeightStepChange: { _ in },
            onArchive: {},
            onDismissSaveError: {}
        )
        .navigationTitle(String(localized: "equipment.editor.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
