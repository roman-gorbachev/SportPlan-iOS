import DesignSystem
import Domain
import SwiftUI

struct AddExerciseDetailsScreen: View {
    private static let descriptionLineLimit = 3...6

    let data: AddExerciseUiData
    let onNameChange: @MainActor (String) -> Void
    let onSelectEquipment: (UUID) -> Void
    let onCreateEquipment: () -> Void
    let onMetricChange: @MainActor (ExerciseMetric) -> Void
    let onIncrementRest: () -> Void
    let onDecrementRest: () -> Void
    let onDescriptionChange: @MainActor (String) -> Void
    let onDayTargetsStep: (PlannedExerciseTargetsStep) -> Void
    let onDismissSaveError: () -> Void

    var body: some View {
        return Form {
            Section {
                TextField(String(localized: "addExercise.name"), text: Binding(get: { return data.name }, set: onNameChange))
                    .foregroundStyle(Palette.textPrimary)
            } header: {
                ListSectionHeader(title: String(localized: "addExercise.name"))
            }
            .appListRow()
            if let newEquipmentTitle = data.loadKind.newEquipmentTitle {
                Section {
                    ForEach(data.equipmentChoices) { item in
                        return AddExerciseEquipmentRow(item: item) {
                            onSelectEquipment(item.id)
                        }
                    }
                    Button(action: onCreateEquipment) {
                        return Label(newEquipmentTitle, systemImage: "plus")
                    }
                    .foregroundStyle(Palette.accent)
                } header: {
                    ListSectionHeader(title: String(localized: "addExercise.equipment.header"))
                }
                .appListRow()
            }
            if data.showsMetricPicker {
                Section {
                    Picker(String(localized: "addExercise.metric"), selection: Binding(get: { return data.metric }, set: onMetricChange)) {
                        return ForEach(ExerciseMetric.allCases, id: \.self) { metric in
                            return Text(metric.title).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } header: {
                    ListSectionHeader(title: String(localized: "addExercise.metric"))
                }
            }
            Section {
                ValueStepper(
                    title: String(localized: "addExercise.rest"),
                    value: data.restText,
                    accessibilityValue: data.restAccessibilityText,
                    canDecrement: data.canDecrementRest,
                    canIncrement: data.canIncrementRest,
                    onDecrement: onDecrementRest,
                    onIncrement: onIncrementRest
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            if let dayContextTitle = data.dayContextTitle, let dayTargets = data.dayTargets {
                Section {
                    PlannedExerciseTargetsSteppers(data: dayTargets, onStep: onDayTargetsStep)
                } header: {
                    ListSectionHeader(title: dayContextTitle)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            Section {
                TextField(
                    String(localized: "addExercise.description.placeholder"),
                    text: Binding(get: { return data.description }, set: onDescriptionChange),
                    axis: .vertical
                )
                .lineLimit(Self.descriptionLineLimit)
                .foregroundStyle(Palette.textPrimary)
            } header: {
                ListSectionHeader(title: String(localized: "addExercise.description"))
            }
            .appListRow()
        }
        .appStyle(Typography.body)
        .appGroupedList()
        .alert(
            String(localized: "addExercise.saveError"),
            isPresented: Binding(get: { return data.isShowingSaveError }, set: { isPresented in
                if !isPresented {
                    onDismissSaveError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        }
    }
}

#Preview {
    FontRegistry.registerFonts()
    let data = AddExerciseUiData(
        loadKind: .equipment(.barbell),
        name: "Жим лёжа",
        equipmentChoices: [
            AddExerciseEquipmentItem(id: UUID(), name: "Олимпийский гриф", weightsText: "20 · 2,5", weightsAccessibilityText: "", isSelected: true),
            AddExerciseEquipmentItem(id: UUID(), name: "EZ-гриф", weightsText: "10 · 2,5", weightsAccessibilityText: "", isSelected: false),
        ],
        metric: .weightReps,
        showsMetricPicker: false,
        restText: "1:30",
        restAccessibilityText: "",
        canIncrementRest: true,
        canDecrementRest: true,
        description: "",
        dayContextTitle: nil,
        dayTargets: nil,
        canSave: true,
        isShowingSaveError: false
    )
    return NavigationStack {
        return AddExerciseDetailsScreen(
            data: data,
            onNameChange: { _ in },
            onSelectEquipment: { _ in },
            onCreateEquipment: {},
            onMetricChange: { _ in },
            onIncrementRest: {},
            onDecrementRest: {},
            onDescriptionChange: { _ in },
            onDayTargetsStep: { _ in },
            onDismissSaveError: {}
        )
        .navigationTitle("Штанга")
        .navigationBarTitleDisplayMode(.inline)
    }
}
