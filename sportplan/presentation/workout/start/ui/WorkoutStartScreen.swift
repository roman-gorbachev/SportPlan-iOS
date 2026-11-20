import DesignSystem
import SwiftUI

struct WorkoutStartScreen: View {
    let data: WorkoutStartUiData
    let onSelectDay: (UUID) -> Void
    let onStartEmpty: () -> Void
    let onCreateProgram: () -> Void
    let onDismissError: () -> Void

    var body: some View {
        return Group {
            if data.programs.isEmpty {
                emptyContent
            } else {
                programList
            }
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

    private var programList: some View {
        return List {
            ForEach(data.programs) { program in
                return Group {
                    Section {
                        WorkoutStartNextDayCard(day: program.nextDay, isStarting: data.isStarting) {
                            onSelectDay(program.nextDay.id)
                        }
                    } header: {
                        ListSectionHeader(title: program.title)
                    }
                    .appListRow()
                    if !program.otherDays.isEmpty {
                        Section {
                            ForEach(program.otherDays) { day in
                                return WorkoutStartDayRow(day: day) {
                                    onSelectDay(day.id)
                                }
                                .disabled(data.isStarting)
                            }
                        } header: {
                            ListSectionHeader(title: String(localized: "workout.start.otherDays"))
                        }
                        .appListRow()
                    }
                }
            }
            Section {
                Button(String(localized: "workout.start.empty"), action: onStartEmpty)
                    .buttonStyle(ChipButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(data.isStarting)
            }
            .listRowBackground(Color.clear)
        }
        .appGroupedList()
    }

    private var emptyContent: some View {
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(String(localized: "workout.empty.title"))
                    .appStyle(Typography.title)
                    .foregroundStyle(Palette.textPrimary)
                Text(String(localized: "workout.empty.message"))
                    .appStyle(Typography.callout)
                    .foregroundStyle(Palette.textSecondary)
                VStack(spacing: Spacing.xs) {
                    Button(action: onStartEmpty) {
                        return Text(String(localized: "workout.empty.start"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(InkButtonStyle())
                    .disabled(data.isStarting)
                    Button(action: onCreateProgram) {
                        return Text(String(localized: "workout.empty.createProgram"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SurfaceButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.l)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.top, Spacing.emptyState)
        }
        .background(Palette.background)
    }
}

#Preview("Программы") {
    FontRegistry.registerFonts()
    let data = WorkoutStartUiData(
        programs: [
            WorkoutStartProgramItem(
                id: UUID(),
                title: "Следующий по программе «Сила 3×»",
                nextDay: WorkoutStartNextDayItem(
                    id: UUID(),
                    label: "День B",
                    name: "Спина и бицепс",
                    exercises: "Тяга штанги в наклоне, Подтягивания, Тяга верхнего блока и ещё 3",
                    lastWorkout: "последний раз ср 11.11"
                ),
                otherDays: [
                    WorkoutStartDayItem(id: UUID(), title: "День C · Ноги и плечи", subtitle: "пт 13.11"),
                    WorkoutStartDayItem(id: UUID(), title: "День A · Грудь и трицепс", subtitle: "пн 16.11"),
                ]
            ),
        ],
        isStarting: false,
        isShowingError: false
    )
    return NavigationStack {
        return WorkoutStartScreen(data: data, onSelectDay: { _ in }, onStartEmpty: {}, onCreateProgram: {}, onDismissError: {})
            .navigationTitle("Тренировка")
    }
}

#Preview("Пусто") {
    FontRegistry.registerFonts()
    return NavigationStack {
        return WorkoutStartScreen(
            data: WorkoutStartUiData(programs: [], isStarting: false, isShowingError: false),
            onSelectDay: { _ in },
            onStartEmpty: {},
            onCreateProgram: {},
            onDismissError: {}
        )
        .navigationTitle("Тренировка")
    }
}
