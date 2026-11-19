import DesignSystem
import Domain
import SwiftUI

struct GymScreen: View {
    let data: GymUiData
    let onAdd: () -> Void
    let onSelect: (UUID) -> Void
    let onAddPlate: () -> Void
    let onSelectPlate: (UUID) -> Void
    let onResetPlates: () -> Void
    let onDismissResetError: () -> Void

    @State private var isConfirmingReset = false

    var body: some View {
        return List {
            equipmentSection
            platesSection
            Section {
                Button(String(localized: "gym.plates.reset")) {
                    isConfirmingReset = true
                }
                .appStyle(Typography.body)
                .foregroundStyle(Palette.textPrimary)
                .appListRow()
                .confirmationDialog(
                    String(localized: "gym.plates.reset.title"),
                    isPresented: $isConfirmingReset,
                    titleVisibility: .visible
                ) {
                    Button(String(localized: "gym.plates.reset.confirm"), role: .destructive, action: onResetPlates)
                    Button(String(localized: "common.cancel"), role: .cancel) {}
                } message: {
                    Text(String(localized: "gym.plates.reset.message"))
                }
            }
        }
        .appGroupedList()
        .alert(
            String(localized: "gym.plates.resetError"),
            isPresented: Binding(get: { return data.isShowingResetError }, set: { isPresented in
                if !isPresented {
                    onDismissResetError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        }
    }

    private var equipmentSection: some View {
        return Section {
            if data.items.isEmpty {
                EmptyStateView(
                    title: String(localized: "gym.empty.title"),
                    message: String(localized: "gym.empty.message"),
                    actionTitle: String(localized: "gym.add"),
                    action: onAdd
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Palette.background)
            } else {
                ForEach(data.items) { item in
                    return GymEquipmentRow(item: item, action: { onSelect(item.id) })
                        .appListRow()
                }
                addButton(title: String(localized: "gym.add"), action: onAdd)
            }
        } header: {
            ListSectionHeader(title: String(localized: "gym.section.equipment"))
        }
    }

    private var platesSection: some View {
        return Section {
            ForEach(data.plates) { item in
                return GymPlateRow(item: item, action: { onSelectPlate(item.id) })
                    .appListRow()
            }
            addButton(title: String(localized: "gym.plates.add"), action: onAddPlate)
        } header: {
            ListSectionHeader(title: String(localized: "gym.section.plates"))
        } footer: {
            if data.plates.isEmpty {
                Text(String(localized: "gym.plates.empty"))
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private func addButton(title: String, action: @escaping () -> Void) -> some View {
        return Button(action: action) {
            return Label(title, systemImage: "plus")
        }
        .appStyle(Typography.body)
        .foregroundStyle(Palette.accent)
        .appListRow()
    }
}

#Preview("Data") {
    FontRegistry.registerFonts()
    let items = [
        GymEquipmentItem(id: UUID(), name: "Олимпийский гриф", kindTitle: "Гриф", weightsText: "20 · 2,5", weightsAccessibilityText: ""),
        GymEquipmentItem(id: UUID(), name: "Гантели", kindTitle: "Гантели", weightsText: "2", weightsAccessibilityText: ""),
    ]
    let plates = [
        GymPlateItem(id: UUID(), plate: PlateStackItem(rgb: 0xD7261E, kilograms: 25), weightText: "25 кг", colorText: "красный"),
        GymPlateItem(id: UUID(), plate: PlateStackItem(rgb: 0x2A2A2A, kilograms: 20), weightText: "20 кг", colorText: "чёрный"),
        GymPlateItem(id: UUID(), plate: PlateStackItem(rgb: 0xA8A8A3, kilograms: 1.25), weightText: "1,25 кг", colorText: "сталь"),
    ]
    return NavigationStack {
        return GymScreen(
            data: GymUiData(items: items, plates: plates, isShowingResetError: false),
            onAdd: {},
            onSelect: { _ in },
            onAddPlate: {},
            onSelectPlate: { _ in },
            onResetPlates: {},
            onDismissResetError: {}
        )
        .navigationTitle(String(localized: "gym.title"))
    }
}

#Preview("Empty") {
    FontRegistry.registerFonts()
    return NavigationStack {
        return GymScreen(
            data: GymUiData(items: [], plates: [], isShowingResetError: false),
            onAdd: {},
            onSelect: { _ in },
            onAddPlate: {},
            onSelectPlate: { _ in },
            onResetPlates: {},
            onDismissResetError: {}
        )
        .navigationTitle(String(localized: "gym.title"))
    }
}
