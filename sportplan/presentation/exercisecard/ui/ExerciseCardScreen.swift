import DesignSystem
import Domain
import SwiftUI

struct ExerciseCardScreen: View {
    private static let headerCollapseOffset: CGFloat = 60

    let data: ExerciseCardUiData
    let onSelectMetric: (ProgressMetric) -> Void

    @State private var isHeaderScrolledAway = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                header
                chartCard
                if data.hasData {
                    recordsGrid
                    sessionsSection
                }
            }
            .padding(.horizontal, Spacing.s)
            .padding(.bottom, Spacing.xl)
        }
        .background(Palette.background)
        .navigationTitle(isHeaderScrolledAway ? data.name : "")
        .navigationBarTitleDisplayMode(.inline)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            return geometry.contentOffset.y + geometry.contentInsets.top > Self.headerCollapseOffset
        } action: { _, isScrolledAway in
            isHeaderScrolledAway = isScrolledAway
        }
    }

    private var header: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(data.meta)
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
            Text(data.name)
                .appStyle(Typography.largeTitle)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
    }

    private var chartCard: some View {
        return VStack(alignment: .leading, spacing: Spacing.s) {
            if data.showsMetricPicker {
                metricPicker
            }
            summary
            if !data.chart.points.isEmpty {
                ExerciseProgressChart(chart: data.chart)
            } else {
                Text(data.chartPlaceholder)
                    .appStyle(Typography.callout)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private var metricPicker: some View {
        let selection = Binding<ProgressMetric>(
            get: { return data.selectedMetric },
            set: { metric in onSelectMetric(metric) }
        )
        return Picker(String(localized: "exerciseCard.metric.picker"), selection: selection) {
            ForEach(data.metricOptions) { option in
                return Text(option.title)
                    .tag(option.metric)
            }
        }
        .pickerStyle(.segmented)
    }

    private var summary: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(data.chart.caption)
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(data.chart.value)
                    .appStyle(Typography.numeralL)
                    .foregroundStyle(Palette.textPrimary)
                if !data.chart.unit.isEmpty {
                    Text(data.chart.unit)
                        .appStyle(Typography.callout)
                        .foregroundStyle(Palette.textSecondary)
                }
                if let delta = data.chart.delta {
                    Text(delta)
                        .appStyle(Typography.callout)
                        .foregroundStyle(data.chart.isDeltaPositive ? Palette.success : Palette.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var recordsGrid: some View {
        return LazyVGrid(columns: recordColumns, alignment: .leading, spacing: Spacing.xs) {
            ForEach(data.records) { item in
                return ExerciseRecordTile(item: item)
            }
        }
    }

    private var recordColumns: [GridItem] {
        let column = GridItem(.flexible(), spacing: Spacing.xs, alignment: .top)
        guard !dynamicTypeSize.isAccessibilitySize else {
            return [column]
        }
        return [column, column]
    }

    private var sessionsSection: some View {
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            ListSectionHeader(title: String(localized: "exerciseCard.sessions.title"))
                .padding(.horizontal, Spacing.xs)
                .padding(.top, Spacing.xs)
            LazyVStack(spacing: .zero) {
                ForEach(data.sessions) { item in
                    ExerciseSessionRow(item: item)
                    if item.id != data.sessions.last?.id {
                        Divider()
                            .overlay(Palette.separator)
                            .padding(.leading, Spacing.m)
                    }
                }
            }
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }
}

private enum ExerciseCardPreviewData {
    static let referenceDate = Date(timeIntervalSince1970: 1_794_787_200)
    static let secondsPerWeek: TimeInterval = 604_800
    static let previewValues: [Double] = [72, 74.5, 75, 77.3, 78, 80.2, 80.5, 82.3]

    static var weighted: ExerciseCardUiData {
        let points = previewValues.enumerated().map { index, value in
            return ExerciseCardChartPoint(
                id: UUID(),
                date: referenceDate.addingTimeInterval(TimeInterval(index - previewValues.count) * secondsPerWeek),
                value: value,
                label: "\(value) кг",
                selectionLabel: "\(value) кг · 13 ноября",
                isRecord: index == previewValues.count - 1,
                isLast: index == previewValues.count - 1
            )
        }
        return ExerciseCardUiData(
            name: "Жим лёжа",
            meta: "Олимпийский гриф · повторы",
            metricOptions: [
                ExerciseCardMetricOption(metric: .estimatedOneRepMax, title: "Расчётный 1ПМ"),
                ExerciseCardMetricOption(metric: .maxWeight, title: "Макс. вес"),
            ],
            selectedMetric: .estimatedOneRepMax,
            chart: ExerciseCardChartUiData(
                caption: "Расчётный 1ПМ · 8 недель",
                value: "82,3",
                unit: "кг",
                delta: "+10,3",
                isDeltaPositive: true,
                valueKind: .kilograms,
                points: points,
                accessibilityLabel: "Расчётный 1ПМ за 8 недель: с 72 кг до 82,3 кг"
            ),
            hasData: true,
            chartPlaceholder: "",
            records: [
                ExerciseCardRecordItem(id: "weight", title: "Макс. вес", value: "65 × 8", caption: "16 ноября"),
                ExerciseCardRecordItem(id: "orm", title: "Расчётный 1ПМ", value: "82,3 кг", caption: "по Эпли"),
            ],
            sessions: [
                ExerciseCardSessionItem(id: UUID(), date: "Пн 16 ноября", sets: "65 × 8 · 65 × 8 · 62,5 × 9", isRecord: true, accessibilityLabel: ""),
                ExerciseCardSessionItem(id: UUID(), date: "Пн 9 ноября", sets: "62,5 × 8 · 62,5 × 8 · 62,5 × 7", isRecord: false, accessibilityLabel: ""),
            ]
        )
    }

    static var empty: ExerciseCardUiData {
        return ExerciseCardUiData(
            name: "Тяга штанги в наклоне",
            meta: "Олимпийский гриф · повторы",
            metricOptions: [ExerciseCardMetricOption(metric: .estimatedOneRepMax, title: "Расчётный 1ПМ")],
            selectedMetric: .estimatedOneRepMax,
            chart: ExerciseCardChartUiData(
                caption: "Расчётный 1ПМ",
                value: "—",
                unit: "",
                delta: nil,
                isDeltaPositive: false,
                valueKind: .kilograms,
                points: [],
                accessibilityLabel: ""
            ),
            hasData: false,
            chartPlaceholder: "Сделай первый подход — здесь появятся график и рекорды.",
            records: [],
            sessions: []
        )
    }
}

#Preview("Weighted") {
    FontRegistry.registerFonts()
    return NavigationStack {
        ExerciseCardScreen(data: ExerciseCardPreviewData.weighted, onSelectMetric: { _ in })
    }
}

#Preview("Empty") {
    FontRegistry.registerFonts()
    return NavigationStack {
        ExerciseCardScreen(data: ExerciseCardPreviewData.empty, onSelectMetric: { _ in })
    }
}
