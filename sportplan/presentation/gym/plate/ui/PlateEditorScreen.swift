import DesignSystem
import Domain
import SwiftUI

struct PlateEditorScreen: View {
    private static let weightFieldHeight: CGFloat = 56

    let data: PlateEditorUiData
    let onWeightChange: @MainActor (String) -> Void
    let onColorChange: @MainActor (PlateColor) -> Void
    let onDelete: () -> Void
    let onDismissSaveError: () -> Void

    @State private var isPickingCustomColor = false
    @FocusState private var isWeightFocused: Bool

    var body: some View {
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                PlatePreview(plate: data.preview)
                    .accessibilityElement()
                    .accessibilityLabel(data.previewAccessibilityText)
                weightBlock
                colorBlock
                if data.isExisting {
                    Button(action: onDelete) {
                        return Text(String(localized: "plate.editor.delete"))
                            .foregroundStyle(Palette.destructive)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SurfaceButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
        }
        .dismissesKeyboard()
        .background(Palette.background)
        .onAppear {
            isWeightFocused = !data.isExisting
        }
        .sheet(isPresented: $isPickingCustomColor) {
            return SystemColorPicker(
                initialRGB: data.color.rgb,
                onSelect: { rgb in onColorChange(PlateColor(rgb: rgb)) },
                onFinish: { isPickingCustomColor = false }
            )
            .presentationDetents([.medium, .large])
        }
        .alert(
            String(localized: "plate.editor.saveError"),
            isPresented: Binding(get: { return data.isShowingSaveError }, set: { isPresented in
                if !isPresented {
                    onDismissSaveError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        }
    }

    private var weightBlock: some View {
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "plate.editor.weight"))
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
                .padding(.leading, Spacing.xxs)
            TextField(text: Binding(get: { return data.weightText }, set: onWeightChange), prompt: Text(verbatim: "")) {
                Text(String(localized: "plate.editor.weight"))
            }
            .keyboardType(.decimalPad)
            .focused($isWeightFocused)
            .appStyle(Typography.numeralM)
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, Spacing.m)
            .frame(minHeight: Self.weightFieldHeight)
            .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: CornerRadius.field))
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.field))
            .onTapGesture {
                isWeightFocused = true
            }
            if let hintText = data.hintText {
                Text(hintText)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.destructive)
                    .padding(.leading, Spacing.xxs)
            }
        }
    }

    private var colorBlock: some View {
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "plate.editor.color"))
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
                .padding(.leading, Spacing.xxs)
            PlatePaletteGrid(
                selectedColor: data.color,
                onSelect: { color in
                    isWeightFocused = false
                    onColorChange(color)
                },
                onPickCustom: {
                    isWeightFocused = false
                    isPickingCustomColor = true
                }
            )
        }
    }
}

#Preview {
    FontRegistry.registerFonts()
    let data = PlateEditorUiData(
        weightText: "25",
        color: PlatePaletteColor.red.color,
        preview: PlateStackItem(rgb: PlatePaletteColor.red.color.rgb, kilograms: 25),
        previewAccessibilityText: "",
        hintText: nil,
        isExisting: true,
        canSave: true,
        isSaving: false,
        isShowingSaveError: false
    )
    return NavigationStack {
        return PlateEditorScreen(
            data: data,
            onWeightChange: { _ in },
            onColorChange: { _ in },
            onDelete: {},
            onDismissSaveError: {}
        )
        .navigationTitle(String(localized: "plate.editor.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
