import DesignSystem
import Domain
import Foundation

enum HistoryUiMapper {
    private static let nextIndexOffset = 1

    static func makeData(_ overview: HistoryOverview, now: Date, calendar: Calendar) -> HistoryUiData {
        return HistoryUiData(
            heatmap: makeHeatmap(overview.heatmap, calendar: calendar),
            sections: makeSections(overview.entries, now: now, calendar: calendar)
        )
    }

    static func makeItem(_ entry: HistoryEntry) -> HistoryWorkoutItem {
        let title = HistoryFormatting.workoutTitle(entry.workout)
        let meta = HistoryFormatting.workoutMeta(entry.workout)
        var spokenParts = [title, meta]
        if entry.recordCount > .zero {
            spokenParts.append(String(localized: "history.workout.records \(entry.recordCount)"))
        }
        return HistoryWorkoutItem(
            id: entry.id,
            title: title,
            meta: meta,
            recordCount: entry.recordCount,
            recordCountText: entry.recordCount.formatted(),
            accessibilityLabel: spokenParts.joined(separator: String(localized: "format.listSeparator"))
        )
    }

    private static func makeSections(_ entries: [HistoryEntry], now: Date, calendar: Calendar) -> [HistoryMonthSection] {
        var sections: [HistoryMonthSection] = []
        for entry in entries {
            let monthStart = calendar.dateInterval(of: .month, for: entry.workout.startedAt)?.start ?? entry.workout.startedAt
            let item = makeItem(entry)
            if let lastIndex = sections.indices.last, sections[lastIndex].id == monthStart {
                sections[lastIndex].items.append(item)
            } else {
                sections.append(HistoryMonthSection(
                    id: monthStart,
                    title: HistoryFormatting.monthTitle(monthStart, now: now, calendar: calendar),
                    items: [item]
                ))
            }
        }
        return sections
    }

    private static func makeHeatmap(_ heatmap: Heatmap, calendar: Calendar) -> HistoryHeatmapUiData {
        let weekCount = heatmap.weeks.count
        let labels = monthLabels(heatmap.weeks, calendar: calendar)
        let columns = heatmap.weeks.enumerated().map { index, week in
            return HeatmapColumn(id: week.start, monthLabel: labels[index], cells: week.days.map(makeCell))
        }
        let summary = heatmap.workoutCount > .zero
            ? String(localized: "history.heatmap.workouts \(heatmap.workoutCount)")
            : String(localized: "history.heatmap.empty")
        return HistoryHeatmapUiData(
            title: String(localized: "history.heatmap.weeks \(weekCount)"),
            summary: summary,
            columns: columns,
            weekdayLabels: weekdayLabels,
            accessibilityLabel: String(localized: "history.heatmap.accessibility \(weekCount)")
        )
    }

    private static var weekdayLabels: [String] {
        return [
            String(localized: "history.heatmap.weekday.monday"),
            "",
            String(localized: "history.heatmap.weekday.wednesday"),
            "",
            String(localized: "history.heatmap.weekday.friday"),
            "",
            "",
        ]
    }

    private static func monthLabels(_ weeks: [HeatmapWeek], calendar: Calendar) -> [String?] {
        let months = weeks.map { week in
            return calendar.component(.month, from: week.start)
        }
        return weeks.indices.map { index -> String? in
            if index == weeks.startIndex {
                let next = index + nextIndexOffset
                let nextStartsMonth = months.indices.contains(next) && months[next] != months[index]
                return nextStartsMonth ? nil : HistoryFormatting.monthLabel(weeks[index].start, calendar: calendar)
            }
            guard months[index] != months[index - nextIndexOffset] else {
                return nil
            }
            return HistoryFormatting.monthLabel(weeks[index].start, calendar: calendar)
        }
    }

    private static func makeCell(_ day: HeatmapDay) -> HeatmapCell {
        return HeatmapCell(
            id: day.date,
            level: day.level.rawValue,
            isToday: day.isToday,
            isFuture: day.isFuture,
            isSelectable: !day.workoutIds.isEmpty,
            accessibilityLabel: HistoryFormatting.cellAccessibility(day)
        )
    }
}
