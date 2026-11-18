import DesignSystem
import SwiftUI

struct ActiveWorkoutScreen: View {
    private static let noteMinimumLines = 3
    private static let addSetButtonHeight: CGFloat = 52

    let data: ActiveWorkoutUiData
    let onAction: (ActiveWorkoutUserAction) -> Void

    var body: some View {
        return List {
            header
            if data.exercises.isEmpty {
                emptyHint
            }
            ForEach(data.exercises) { exercise in
                return exerciseSection(exercise)
            }
            addExerciseSection
            noteSection
        }
        .appGroupedList()
        .navigationTitle(data.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                return menu
            }
            ToolbarItem(placement: .principal) {
                return elapsed
            }
            ToolbarItem(placement: .confirmationAction) {
                return Button(String(localized: "workout.active.finish")) {
                    onAction(.requestFinish)
                }
            }
        }
        .sheet(item: Binding(get: { return data.editor }, set: { editor in
            if editor == nil {
                onAction(.closeEditor)
            }
        })) { editor in
            return SetEditorScreen(data: editor, onAction: onAction)
        }
        .alert(
            confirmationTitle,
            isPresented: Binding(get: { return data.confirmation != nil }, set: { isPresented in
                if !isPresented {
                    onAction(.dismissConfirmation)
                }
            }),
            presenting: data.confirmation
        ) { confirmation in
            Button(String(localized: "workout.confirm.keepGoing"), role: .cancel) {}
            Button(confirmButtonTitle(confirmation), role: .destructive) {
                onAction(.confirm(confirmation))
            }
        } message: { confirmation in
            return Text(confirmationMessage(confirmation))
        }
        .alert(
            String(localized: "common.error.title"),
            isPresented: Binding(get: { return data.isShowingError }, set: { isPresented in
                if !isPresented {
                    onAction(.dismissError)
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        } message: {
            Text(String(localized: "workout.active.error"))
        }
    }

    private var header: some View {
        return Section {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let subtitle = data.subtitle {
                    Text(subtitle)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                Text(data.title)
                    .appStyle(Typography.largeTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: .zero, leading: Spacing.xs, bottom: .zero, trailing: Spacing.xs))
        }
    }

    private var emptyHint: some View {
        return Section {
            Text(String(localized: "workout.active.empty"))
                .appStyle(Typography.callout)
                .foregroundStyle(Palette.textSecondary)
                .listRowBackground(Color.clear)
        }
    }

    private func exerciseSection(_ exercise: ActiveExerciseItem) -> some View {
        return Section {
            ForEach(exercise.sets) { row in
                return SetRow(
                    row: row,
                    onEdit: { onAction(.editSet(id: row.id)) },
                    onAction: { onAction(.tapSetAction(id: row.id)) }
                )
                .swipeActions(edge: .trailing) {
                    Button(String(localized: "workout.set.delete"), systemImage: "trash", role: .destructive) {
                        onAction(.removeSet(id: row.id))
                    }
                }
            }
            HStack(spacing: Spacing.xs) {
                addSetButton(title: String(localized: "workout.active.addSet")) {
                    onAction(.addSet(workoutExerciseId: exercise.id, isWarmup: false))
                }
                addSetButton(title: String(localized: "workout.active.addWarmup")) {
                    onAction(.addSet(workoutExerciseId: exercise.id, isWarmup: true))
                }
            }
        } header: {
            ActiveExerciseHeader(exercise: exercise)
        }
        .appListRow()
    }

    private func addSetButton(title: String, action: @escaping () -> Void) -> some View {
        return Button(action: action) {
            return Label(title, systemImage: "plus")
                .appStyle(Typography.callout)
                .foregroundStyle(Palette.textPrimary)
                .frame(maxWidth: .infinity, minHeight: Self.addSetButtonHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }

    private var addExerciseSection: some View {
        return Section {
            Button(String(localized: "workout.active.addExercise")) {
                onAction(.addExercise)
            }
            .buttonStyle(ChipButtonStyle())
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
    }

    private var noteSection: some View {
        return Section {
            TextField(
                String(localized: "workout.note.placeholder"),
                text: Binding(get: { return data.note }, set: { text in onAction(.updateNote(text)) }),
                axis: .vertical
            )
            .appStyle(Typography.body)
            .foregroundStyle(Palette.textPrimary)
            .lineLimit(Self.noteMinimumLines, reservesSpace: true)
        } header: {
            ListSectionHeader(title: String(localized: "workout.note.title"))
                .textCase(nil)
        }
        .appListRow()
    }

    private var menu: some View {
        return Menu {
            Button(String(localized: "workout.active.addExercise"), systemImage: "plus") {
                onAction(.addExercise)
            }
            Button(String(localized: "settings.title"), systemImage: "gearshape") {
                onAction(.openSettings)
            }
            Button(String(localized: "workout.active.cancel"), systemImage: "xmark", role: .destructive) {
                onAction(.requestCancel)
            }
        } label: {
            return Image(systemName: "ellipsis")
        }
        .accessibilityLabel(String(localized: "workout.active.menu"))
    }

    private var elapsed: some View {
        return Text(data.startedAt, style: .timer)
            .appStyle(Typography.numeralS)
            .foregroundStyle(Palette.textPrimary)
            .accessibilityLabel(String(localized: "workout.active.elapsed"))
    }

    private var confirmationTitle: String {
        switch data.confirmation {
        case .finish:
            return String(localized: "workout.confirm.finish.title")
        case .discardEmpty:
            return String(localized: "workout.confirm.discard.title")
        case .cancel:
            return String(localized: "workout.confirm.cancel.title")
        case nil:
            return ""
        }
    }

    private func confirmationMessage(_ confirmation: ActiveWorkoutConfirmation) -> String {
        switch confirmation {
        case let .finish(incompleteSetCount):
            return String(localized: "workout.confirm.finish.message \(incompleteSetCount)")
        case .discardEmpty:
            return String(localized: "workout.confirm.discard.message")
        case .cancel:
            return String(localized: "workout.confirm.cancel.message")
        }
    }

    private func confirmButtonTitle(_ confirmation: ActiveWorkoutConfirmation) -> String {
        switch confirmation {
        case .finish, .discardEmpty:
            return String(localized: "workout.active.finish")
        case .cancel:
            return String(localized: "workout.active.cancel")
        }
    }
}

#Preview {
    FontRegistry.registerFonts()
    let plates = SetRowPlates(
        plates: [PlateStackItem(rgb: 0x1F5FBF, kilograms: 20), PlateStackItem(rgb: 0xD7261E, kilograms: 2.5)],
        remainder: nil,
        accessibilityLabel: "На каждую сторону: 20 и 2,5 кг"
    )
    let bench = ActiveExerciseItem(id: UUID(), name: "Жим лёжа", summary: "2 из 3 · 8–12 повт.", sets: [
        SetRowItem(id: UUID(), number: 1, value: .weightReps(weight: "40", reps: "10"), valueAccessibility: "40 кг, 10 повторов", isWarmup: true, state: .completed, caption: "было 40 × 10", plates: nil, isTimed: false, isEditable: true),
        SetRowItem(id: UUID(), number: 2, value: .weightReps(weight: "65", reps: "8"), valueAccessibility: "65 кг, 8 повторов", isWarmup: false, state: .completed, caption: "было 62,5 × 8", plates: plates, isTimed: false, isEditable: true),
        SetRowItem(id: UUID(), number: 3, value: .weightReps(weight: "65", reps: "8"), valueAccessibility: "65 кг, 8 повторов", isWarmup: false, state: .current, caption: "было 62,5 × 7", plates: plates, isTimed: false, isEditable: true),
        SetRowItem(id: UUID(), number: 4, value: .weightReps(weight: "65", reps: "8"), valueAccessibility: "65 кг, 8 повторов", isWarmup: false, state: .planned, caption: "план", plates: plates, isTimed: false, isEditable: true),
    ])
    let plank = ActiveExerciseItem(id: UUID(), name: "Планка", summary: "0 из 2", sets: [
        SetRowItem(id: UUID(), number: 1, value: .duration(text: "1:15", runningSince: Date().addingTimeInterval(-47)), valueAccessibility: "1 минута 15 секунд", isWarmup: false, state: .running, caption: "идёт · было 1:15", plates: nil, isTimed: true, isEditable: false),
        SetRowItem(id: UUID(), number: 2, value: .bodyweightReps(addedWeight: nil, reps: "12"), valueAccessibility: "12 повторов", isWarmup: false, state: .planned, caption: nil, plates: nil, isTimed: false, isEditable: true),
    ])
    let data = ActiveWorkoutUiData(
        title: "Грудь и трицепс",
        subtitle: "День A · Сила 3×",
        startedAt: Date().addingTimeInterval(-2_052),
        exercises: [bench, plank],
        note: "",
        editor: nil,
        confirmation: nil,
        isShowingError: false
    )
    return NavigationStack {
        return ActiveWorkoutScreen(data: data, onAction: { _ in })
    }
}
