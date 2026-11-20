import DesignSystem
import Domain
import SwiftUI

struct ExerciseEditorScreen: View {
    private static let descriptionLineLimit = 3...6
    private static let lockIconName = "lock.fill"

    let data: ExerciseEditorUiData
    let onNameChange: @MainActor (String) -> Void
    let onDescriptionChange: @MainActor (String) -> Void
    let onSelectEquipment: (UUID) -> Void
    let onMetricChange: @MainActor (ExerciseMetric) -> Void
    let onIncrementRest: () -> Void
    let onDecrementRest: () -> Void
    let onArchive: () -> Void
    let onConfirmArchive: () -> Void
    let onCancelArchive: () -> Void
    let onDismissSaveError: () -> Void
    let onDismissArchiveError: () -> Void

    var body: some View {
        return Form {
            Section {
                TextField(String(localized: "addExercise.name"), text: Binding(get: { return data.name }, set: onNameChange))
                    .foregroundStyle(Palette.textPrimary)
            } header: {
                ListSectionHeader(title: String(localized: "addExercise.name"))
            }
            .appListRow()
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
            if let equipmentHeader = data.equipmentHeader {
                equipmentSection(header: equipmentHeader)
            }
            if data.showsMetric {
                metricSection
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
            Section {
                Button(String(localized: "library.archive"), role: .destructive, action: onArchive)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Palette.destructive)
                    .confirmationDialog(
                        archiveTitle,
                        isPresented: isConfirmingArchive,
                        titleVisibility: .visible,
                        presenting: data.pendingArchive
                    ) { _ in
                        Button(String(localized: "library.archive"), role: .destructive, action: onConfirmArchive)
                        Button(String(localized: "common.cancel"), role: .cancel) {}
                    } message: { confirmation in
                        Text(archiveMessage(confirmation))
                    }
            }
            .appListRow()
        }
        .appStyle(Typography.body)
        .appGroupedList()
        .dismissesKeyboard()
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
        .alert(
            String(localized: "library.archive.error"),
            isPresented: Binding(get: { return data.isShowingArchiveError }, set: { isPresented in
                if !isPresented {
                    onDismissArchiveError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        }
    }

    private func equipmentSection(header: String) -> some View {
        return Section {
            ForEach(data.equipmentChoices) { item in
                return AddExerciseEquipmentRow(item: item) {
                    onSelectEquipment(item.id)
                }
            }
        } header: {
            ListSectionHeader(title: header)
        } footer: {
            if let equipmentLockHint = data.equipmentLockHint {
                Text(equipmentLockHint)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .appListRow()
    }

    @ViewBuilder
    private var metricSection: some View {
        if data.isMetricLocked {
            Section {
                HStack(spacing: Spacing.s) {
                    Text(String(localized: "addExercise.metric"))
                        .foregroundStyle(Palette.textPrimary)
                    Spacer(minLength: Spacing.s)
                    Text(data.metric.title)
                        .foregroundStyle(Palette.textSecondary)
                    Image(systemName: Self.lockIconName)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "exerciseEditor.metric.locked.accessibility \(data.metric.title)"))
            }
            .appListRow()
        } else {
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
    }

    private var isConfirmingArchive: Binding<Bool> {
        return Binding(get: { return data.pendingArchive != nil }, set: { isPresented in
            if !isPresented {
                onCancelArchive()
            }
        })
    }

    private var archiveTitle: String {
        guard let pendingArchive = data.pendingArchive else {
            return ""
        }
        return String(localized: "library.archive.title \(pendingArchive.exerciseName)")
    }

    private func archiveMessage(_ confirmation: LibraryArchiveConfirmation) -> String {
        guard confirmation.programDayCount > 0 else {
            return String(localized: "library.archive.message.unused")
        }
        return String(localized: "library.archive.message.days \(confirmation.programDayCount)")
    }
}

#Preview {
    FontRegistry.registerFonts()
    let data = ExerciseEditorUiData(
        title: "Жим лёжа",
        name: "Жим лёжа",
        description: "Лопатки сведены, пауза на груди.",
        equipmentHeader: "Оборудование · только грифы",
        equipmentChoices: [
            AddExerciseEquipmentItem(id: UUID(), name: "Олимпийский гриф", weightsText: "20 · 2,5", weightsAccessibilityText: "", isSelected: true),
            AddExerciseEquipmentItem(id: UUID(), name: "EZ-гриф", weightsText: "10 · 2,5", weightsAccessibilityText: "", isSelected: false),
        ],
        equipmentLockHint: "По упражнению уже есть подходы, поэтому гриф можно сменить только на другой гриф.",
        showsMetric: false,
        metric: .weightReps,
        isMetricLocked: true,
        restText: "1:30",
        restAccessibilityText: "",
        canIncrementRest: true,
        canDecrementRest: true,
        canSave: true,
        pendingArchive: nil,
        isShowingSaveError: false,
        isShowingArchiveError: false
    )
    return NavigationStack {
        return ExerciseEditorScreen(
            data: data,
            onNameChange: { _ in },
            onDescriptionChange: { _ in },
            onSelectEquipment: { _ in },
            onMetricChange: { _ in },
            onIncrementRest: {},
            onDecrementRest: {},
            onArchive: {},
            onConfirmArchive: {},
            onCancelArchive: {},
            onDismissSaveError: {},
            onDismissArchiveError: {}
        )
        .navigationTitle(data.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
