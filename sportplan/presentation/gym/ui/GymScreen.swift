import DesignSystem
import Domain
import SwiftUI

struct GymScreen: View {
    let data: GymUiData
    let onAdd: () -> Void
    let onSelect: (UUID) -> Void

    var body: some View {
        return Group {
            if data.items.isEmpty {
                EmptyStateView(
                    title: String(localized: "gym.empty.title"),
                    message: String(localized: "gym.empty.message"),
                    actionTitle: String(localized: "gym.add"),
                    action: onAdd
                )
            } else {
                equipmentList
            }
        }
    }

    private var equipmentList: some View {
        return List {
            Section {
                ForEach(data.items) { item in
                    return GymEquipmentRow(item: item, action: { onSelect(item.id) })
                        .appListRow()
                }
                Button(action: onAdd) {
                    return Label(String(localized: "gym.add"), systemImage: "plus")
                }
                .appStyle(Typography.body)
                .foregroundStyle(Palette.accent)
                .appListRow()
            } header: {
                ListSectionHeader(title: String(localized: "gym.section.equipment"))
            }
        }
        .appGroupedList()
    }
}

#Preview("Data") {
    FontRegistry.registerFonts()
    let items = [
        GymEquipmentItem(id: UUID(), name: "Олимпийский гриф", kindTitle: "Гриф", weightsText: "20 · 2,5", weightsAccessibilityText: ""),
        GymEquipmentItem(id: UUID(), name: "Гантели", kindTitle: "Гантели", weightsText: "2", weightsAccessibilityText: ""),
    ]
    return NavigationStack {
        return GymScreen(data: GymUiData(items: items), onAdd: {}, onSelect: { _ in })
            .navigationTitle(String(localized: "gym.title"))
    }
}

#Preview("Empty") {
    FontRegistry.registerFonts()
    return NavigationStack {
        return GymScreen(data: GymUiData(items: []), onAdd: {}, onSelect: { _ in })
            .navigationTitle(String(localized: "gym.title"))
    }
}
