import Charts
import DesignSystem
import SwiftUI

struct ExerciseProgressChart: View {
    private static let height: CGFloat = 180
    private static let lineWidth: CGFloat = 2
    private static let pointDiameter: CGFloat = 7
    private static let recordPointDiameter: CGFloat = 11
    private static let recordStrokeWidth: CGFloat = 1.5
    private static let gridLineWidth: CGFloat = 1
    private static let valueAxisMarkCount = 3

    let chart: ExerciseCardChartUiData

    @State private var selectedDate: Date?

    var body: some View {
        return Chart {
            ForEach(chart.points) { point in
                LineMark(
                    x: .value(String(localized: "exerciseCard.chart.axisDate"), point.date),
                    y: .value(String(localized: "exerciseCard.chart.axisValue"), point.value)
                )
                .foregroundStyle(Palette.accent)
                .lineStyle(StrokeStyle(lineWidth: Self.lineWidth))
                PointMark(
                    x: .value(String(localized: "exerciseCard.chart.axisDate"), point.date),
                    y: .value(String(localized: "exerciseCard.chart.axisValue"), point.value)
                )
                .symbol {
                    pointSymbol(point)
                }
                .annotation(position: .top, spacing: Spacing.xxs) {
                    if point.isLast && selectedPoint == nil {
                        Text(point.label)
                            .appStyle(Typography.caption)
                            .foregroundStyle(Palette.textPrimary)
                    }
                }
            }
            if let selectedPoint {
                RuleMark(x: .value(String(localized: "exerciseCard.chart.axisDate"), selectedPoint.date))
                    .foregroundStyle(Palette.separatorStrong)
                    .annotation(position: .top, spacing: Spacing.xxs, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        selectionPlate(selectedPoint)
                    }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: Self.gridLineWidth))
                    .foregroundStyle(Palette.separator)
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .font(Typography.caption.font)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: Self.valueAxisMarkCount)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: Self.gridLineWidth))
                    .foregroundStyle(Palette.separator)
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        Text(ExerciseCardFormatting.axisValue(number, kind: chart.valueKind))
                            .appStyle(Typography.caption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
            }
        }
        .chartXSelection(value: $selectedDate)
        .environment(\.locale, AppLocale.current)
        .frame(height: Self.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chart.accessibilityLabel)
    }

    private var selectedPoint: ExerciseCardChartPoint? {
        guard let selectedDate else {
            return nil
        }
        return chart.points.min { lhs, rhs in
            return abs(lhs.date.timeIntervalSince(selectedDate)) < abs(rhs.date.timeIntervalSince(selectedDate))
        }
    }

    private func pointSymbol(_ point: ExerciseCardChartPoint) -> some View {
        let diameter = point.isRecord ? Self.recordPointDiameter : Self.pointDiameter
        return Circle()
            .fill(point.isRecord ? Palette.record : Palette.accent)
            .overlay {
                if point.isRecord {
                    Circle()
                        .strokeBorder(Palette.onRecord, lineWidth: Self.recordStrokeWidth)
                }
            }
            .frame(width: diameter, height: diameter)
    }

    private func selectionPlate(_ point: ExerciseCardChartPoint) -> some View {
        return Text(point.selectionLabel)
            .appStyle(Typography.caption)
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: CornerRadius.chip))
    }
}
