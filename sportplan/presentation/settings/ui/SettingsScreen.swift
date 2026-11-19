import DesignSystem
import SwiftUI

struct SettingsScreen: View {
    let data: SettingsUiData
    let onOpenGym: () -> Void

    var body: some View {
        return List {
            Section {
                NavigationRow(title: String(localized: "settings.gym.title"), subtitle: equipmentSummary, action: onOpenGym)
                    .appListRow()
            } header: {
                ListSectionHeader(title: String(localized: "settings.section.gym"))
            }
            Section {
                LabeledContent(String(localized: "settings.version"), value: data.appVersion)
                    .appStyle(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                    .appListRow()
            } header: {
                ListSectionHeader(title: String(localized: "settings.section.about"))
            }
        }
        .appGroupedList()
    }

    private var equipmentSummary: String {
        let equipmentText = data.equipmentCount > 0
            ? String(localized: "settings.gym.equipmentCount \(data.equipmentCount)")
            : String(localized: "settings.gym.empty")
        guard data.plateCount > 0 else {
            return equipmentText
        }
        return String(localized: "settings.gym.summary \(equipmentText) \(String(localized: "settings.gym.plateCount \(data.plateCount)"))")
    }
}

#Preview {
    FontRegistry.registerFonts()
    return NavigationStack {
        return SettingsScreen(data: SettingsUiData(equipmentCount: 6, plateCount: 7, appVersion: "1.0"), onOpenGym: {})
            .navigationTitle(String(localized: "settings.title"))
    }
}
