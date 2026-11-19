import Domain
import Foundation

enum ExerciseCardUiMapper {
    static func makeData(_ card: ExerciseCard, selectedMetric: ProgressMetric) -> ExerciseCardUiData {
        let series = card.series.first { item in
            return item.metric == selectedMetric
        } ?? ProgressSeries(metric: selectedMetric, points: [])
        return ExerciseCardUiData(
            name: card.exercise.exercise.name,
            meta: meta(card.exercise),
            metricOptions: card.series.map { item in
                return ExerciseCardMetricOption(metric: item.metric, title: item.metric.title)
            },
            selectedMetric: selectedMetric,
            chart: makeChart(series),
            hasData: card.hasData,
            chartPlaceholder: card.hasData
                ? String(localized: "exerciseCard.chart.noPoints \(EstimatedOneRepMax.maximumReps)")
                : String(localized: "exerciseCard.empty"),
            records: card.records.map { record in
                return makeRecord(record, exercise: card.exercise)
            },
            sessions: card.sessions.map { session in
                return makeSession(session, card: card)
            }
        )
    }

    private static func meta(_ exercise: LibraryExercise) -> String {
        let load = exercise.equipment?.name ?? String(localized: "exerciseCard.bodyweight")
        return String(localized: "format.dotSeparated \(load) \(exercise.metric.listTitle)")
    }

    private static func makeChart(_ series: ProgressSeries) -> ExerciseCardChartUiData {
        let metric = series.metric
        let kind = metric.valueKind
        guard let latest = series.latest, let first = series.points.first else {
            return ExerciseCardChartUiData(
                caption: metric.title,
                value: String(localized: "workout.set.noValue"),
                unit: "",
                delta: nil,
                isDeltaPositive: false,
                valueKind: kind,
                points: [],
                accessibilityLabel: String(localized: "exerciseCard.chart.empty \(metric.title)")
            )
        }
        let window = String(localized: "exerciseCard.chart.window \(ProgressSeries.windowWeeks)")
        let lastId = series.points.last?.id
        let points = series.points.map { point in
            let label = ExerciseCardFormatting.valueWithUnit(point.value, kind: kind)
            return ExerciseCardChartPoint(
                id: point.id,
                date: point.date,
                value: ExerciseCardFormatting.plotValue(point.value, kind: kind),
                label: label,
                selectionLabel: String(localized: "format.dotSeparated \(label) \(ExerciseCardFormatting.recordDate(point.date))"),
                isRecord: point.isRecord,
                isLast: point.id == lastId
            )
        }
        return ExerciseCardChartUiData(
            caption: String(localized: "format.dotSeparated \(metric.title) \(window)"),
            value: ExerciseCardFormatting.value(latest, kind: kind),
            unit: ExerciseCardFormatting.unit(kind),
            delta: series.delta.map { delta in
                return ExerciseCardFormatting.delta(delta, kind: kind)
            },
            isDeltaPositive: (series.delta ?? .zero) > .zero,
            valueKind: kind,
            points: points,
            accessibilityLabel: chartAccessibilityLabel(series, first: first.value, latest: latest, window: window)
        )
    }

    private static func chartAccessibilityLabel(_ series: ProgressSeries, first: Int, latest: Int, window: String) -> String {
        let kind = series.metric.valueKind
        let latestText = ExerciseCardFormatting.valueWithUnit(latest, kind: kind)
        guard series.delta != nil else {
            return String(localized: "exerciseCard.chart.single \(series.metric.title) \(latestText)")
        }
        let firstText = ExerciseCardFormatting.valueWithUnit(first, kind: kind)
        return String(localized: "exerciseCard.chart.summary \(series.metric.title) \(window) \(firstText) \(latestText)")
    }

    private static func makeRecord(_ record: PersonalRecord, exercise: LibraryExercise) -> ExerciseCardRecordItem {
        let value: String
        let caption: String
        switch record.kind {
        case .estimatedOneRepMax:
            value = ExerciseCardFormatting.valueWithUnit(record.value, kind: .kilograms)
            caption = String(localized: "exerciseCard.record.epley")
        case .maxWeight, .maxReps, .maxWeightedReps, .maxDuration:
            value = WorkoutFormatting.setSummary(record.entry, exercise: exercise)
            caption = ExerciseCardFormatting.recordDate(record.date)
        }
        return ExerciseCardRecordItem(id: record.kind.title, title: record.kind.title, value: value, caption: caption)
    }

    private static func makeSession(_ session: ExerciseSession, card: ExerciseCard) -> ExerciseCardSessionItem {
        let date = ExerciseCardFormatting.sessionDate(session.date)
        let sets = session.sets.map { entry in
            return WorkoutFormatting.setSummary(entry, exercise: card.exercise)
        }.joined(separator: String(localized: "exerciseCard.sets.separator"))
        let isRecord = card.hasRecord(in: session)
        let parts = [date, isRecord ? String(localized: "workout.set.record") : nil, sets].compactMap { part in
            return part
        }
        return ExerciseCardSessionItem(
            id: session.id,
            date: date,
            sets: sets,
            isRecord: isRecord,
            accessibilityLabel: parts.joined(separator: String(localized: "format.listSeparator"))
        )
    }
}
