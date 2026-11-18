import DesignSystem
import SwiftUI

struct ProgramDayFields: View {
    let label: String
    let name: String
    let onLabelChange: @MainActor (String) -> Void
    let onNameChange: @MainActor (String) -> Void

    var body: some View {
        return Group {
            LabeledContent {
                TextField(String(localized: "programDay.label.placeholder"), text: Binding(get: { return label }, set: onLabelChange))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            } label: {
                Text(String(localized: "programDay.label"))
                    .foregroundStyle(Palette.textSecondary)
            }
            LabeledContent {
                TextField(String(localized: "programDay.name.placeholder"), text: Binding(get: { return name }, set: onNameChange))
            } label: {
                Text(String(localized: "programDay.name"))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .foregroundStyle(Palette.textPrimary)
    }
}
