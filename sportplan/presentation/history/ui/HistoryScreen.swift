import DesignSystem
import Foundation
import SwiftUI

struct HistoryScreen: View {
    let data: HistoryUiData
    let onSelectDay: (Date) -> Void
    let onOpenWorkout: (UUID) -> Void
    let onStartWorkout: () -> Void

    var body: some View {
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.s) {
                HistoryHeatmapCard(data: data.heatmap, onSelectDay: onSelectDay)
                if data.isEmpty {
                    HistoryEmptyContent(onStartWorkout: onStartWorkout)
                } else {
                    ForEach(data.sections) { section in
                        return HistoryMonthSectionView(section: section, onOpenWorkout: onOpenWorkout)
                    }
                }
            }
            .padding(.horizontal, Spacing.s)
            .padding(.bottom, Spacing.xl)
        }
        .background(Palette.background)
    }
}

private enum HistoryPreviewData {
    static let referenceDate = Date(timeIntervalSince1970: 1_794_787_200)
    static let secondsPerDay: TimeInterval = 86_400
    static let weekCount = 15
    static let daysPerWeek = 7
    static let levelCount = 5
    static let monthLabelInterval = 4
    static let todayWeekday = 3
    static let weekLevelStride = 3
    static let dayLevelStride = 5

    static func data(isEmpty: Bool) -> HistoryUiData {
        let columns = (0..<weekCount).map { week in
            let start = referenceDate.addingTimeInterval(TimeInterval(week * daysPerWeek) * secondsPerDay)
            return HeatmapColumn(
                id: start,
                monthLabel: week % monthLabelInterval == .zero ? "ноя" : nil,
                cells: (0..<daysPerWeek).map { day in
                    let level = isEmpty ? .zero : (week * weekLevelStride + day * dayLevelStride) % levelCount
                    return HeatmapCell(
                        id: start.addingTimeInterval(TimeInterval(day) * secondsPerDay),
                        level: level,
                        isToday: week == weekCount - 1 && day == todayWeekday,
                        isFuture: week == weekCount - 1 && day > todayWeekday,
                        isSelectable: level > .zero,
                        accessibilityLabel: ""
                    )
                }
            )
        }
        let heatmap = HistoryHeatmapUiData(
            title: "15 недель",
            summary: isEmpty ? "пока пусто" : "24 тренировки",
            columns: columns,
            weekdayLabels: ["Пн", "", "Ср", "", "Пт", "", ""],
            accessibilityLabel: ""
        )
        let items = [
            HistoryWorkoutItem(id: UUID(), title: "Пн 16 · День A · Грудь и трицепс", meta: "48 мин · 17 подходов", recordCount: 0, recordCountText: "0", accessibilityLabel: ""),
            HistoryWorkoutItem(id: UUID(), title: "Пт 13 · День C · Ноги и плечи", meta: "52 мин · 19 подходов", recordCount: 1, recordCountText: "1", accessibilityLabel: ""),
        ]
        let sections = isEmpty ? [] : [HistoryMonthSection(id: referenceDate, title: "Ноябрь", items: items)]
        return HistoryUiData(heatmap: heatmap, sections: sections)
    }
}

#Preview("List") {
    FontRegistry.registerFonts()
    return NavigationStack {
        HistoryScreen(data: HistoryPreviewData.data(isEmpty: false), onSelectDay: { _ in }, onOpenWorkout: { _ in }, onStartWorkout: {})
            .navigationTitle("История")
    }
}

#Preview("Empty") {
    FontRegistry.registerFonts()
    return NavigationStack {
        HistoryScreen(data: HistoryPreviewData.data(isEmpty: true), onSelectDay: { _ in }, onOpenWorkout: { _ in }, onStartWorkout: {})
            .navigationTitle("История")
    }
}
