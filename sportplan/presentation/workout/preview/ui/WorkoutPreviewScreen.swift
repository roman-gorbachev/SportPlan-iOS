import DesignSystem
import SwiftUI

struct WorkoutPreviewScreen: View {
    let data: WorkoutPreviewUiData
    let onStart: () -> Void
    let onDismissError: () -> Void

    var body: some View {
        return List {
            Section {
                header
            }
            .appListRow()
            if let tip = data.tip {
                Section {
                    tipView(tip)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            Section {
                if data.exercises.isEmpty {
                    Text(String(localized: "workout.start.exercises.none"))
                        .appStyle(Typography.callout)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    ForEach(data.exercises) { exercise in
                        return WorkoutPreviewExerciseRow(exercise: exercise)
                    }
                }
            } header: {
                ListSectionHeader(title: String(localized: "workout.preview.exercises"))
            }
            .appListRow()
        }
        .appGroupedList()
        .safeAreaInset(edge: .bottom) {
            startButton
        }
        .alert(
            String(localized: "common.error.title"),
            isPresented: Binding(get: { return data.isShowingError }, set: { isPresented in
                if !isPresented {
                    onDismissError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        } message: {
            Text(String(localized: "workout.start.error"))
        }
    }

    private var header: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            if let label = data.label {
                Text(label)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            Text(data.name)
                .appStyle(Typography.title)
                .foregroundStyle(Palette.textPrimary)
            Text(String(localized: "format.dotSeparated \(data.programName) \(data.lastWorkout)"))
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }

    private func tipView(_ tip: String) -> some View {
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Image(systemName: "lightbulb")
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)
            Text(tip)
                .appStyle(Typography.callout)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: .zero)
        }
        .padding(Spacing.s)
        .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: CornerRadius.field))
    }

    private var startButton: some View {
        return Button(action: onStart) {
            return Text(String(localized: "workout.start.begin"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(InkButtonStyle())
        .disabled(data.isStarting)
        .accessibilityLabel(String(localized: "workout.start.begin.accessibility \(data.name)"))
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.s)
    }
}

#Preview {
    FontRegistry.registerFonts()
    let data = WorkoutPreviewUiData(
        label: "День A",
        name: "Грудь и трицепс",
        programName: "Сила 3×",
        lastWorkout: "последний раз ср 18.11",
        exercises: [
            WorkoutPreviewExerciseItem(id: UUID(), name: "Жим лёжа", plan: "3 × 8–12 · 65 кг", planAccessibility: "3 подхода по 8–12 повторений, 65 кг"),
            WorkoutPreviewExerciseItem(id: UUID(), name: "Отжимания на брусьях", plan: "3 × 8–12 · +10 кг", planAccessibility: "3 подхода по 8–12 повторений, +10 кг"),
            WorkoutPreviewExerciseItem(id: UUID(), name: "Планка", plan: "3 × 1:00", planAccessibility: "3 подхода по 1 минуте"),
        ],
        tip: "Жим лёжа: в прошлый раз всё выполнено — попробуй 67,5 кг",
        isStarting: false,
        isShowingError: false
    )
    return NavigationStack {
        return WorkoutPreviewScreen(data: data, onStart: {}, onDismissError: {})
            .navigationBarTitleDisplayMode(.inline)
    }
}
