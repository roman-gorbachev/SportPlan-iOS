import SwiftUI

public struct HeatmapGrid: View {
    private static let cellSpacing: CGFloat = 3
    private static let todayLineWidth: CGFloat = 2
    private static let futureLineWidth: CGFloat = 1
    private static let cellAspectRatio: CGFloat = 1

    private let columns: [HeatmapColumn]
    private let weekdayLabels: [String]
    private let accessibilityLabel: String
    private let onSelect: (Date) -> Void

    public init(
        columns: [HeatmapColumn],
        weekdayLabels: [String],
        accessibilityLabel: String,
        onSelect: @escaping (Date) -> Void
    ) {
        self.columns = columns
        self.weekdayLabels = weekdayLabels
        self.accessibilityLabel = accessibilityLabel
        self.onSelect = onSelect
    }

    public var body: some View {
        return Grid(horizontalSpacing: Self.cellSpacing, verticalSpacing: Self.cellSpacing) {
            GridRow {
                Color.clear
                    .gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(columns) { column in
                    return monthLabel(column.monthLabel)
                }
            }
            ForEach(weekdayLabels.indices, id: \.self) { row in
                return GridRow {
                    Text(weekdayLabels[row])
                        .appStyle(Typography.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                        .fixedSize()
                        .gridColumnAlignment(.leading)
                        .accessibilityHidden(true)
                    ForEach(columns) { column in
                        return cellView(column: column, row: row)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func monthLabel(_ label: String?) -> some View {
        return Text(verbatim: " ")
            .appStyle(Typography.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                if let label {
                    Text(label)
                        .appStyle(Typography.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func cellView(column: HeatmapColumn, row: Int) -> some View {
        if row < column.cells.count {
            let cell = column.cells[row]
            HeatmapCellView(cell: cell)
                .aspectRatio(Self.cellAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard cell.isSelectable else {
                        return
                    }
                    onSelect(cell.id)
                }
                .accessibilityElement()
                .accessibilityLabel(cell.accessibilityLabel)
                .accessibilityAddTraits(cell.isSelectable ? .isButton : [])
                .accessibilityAction {
                    guard cell.isSelectable else {
                        return
                    }
                    onSelect(cell.id)
                }
                .accessibilitySortPriority(sortPriority(column: column, row: row))
        } else {
            Color.clear
        }
    }

    private func sortPriority(column: HeatmapColumn, row: Int) -> Double {
        let columnIndex = columns.firstIndex { candidate in return candidate.id == column.id } ?? .zero
        let cellCount = columns.count * weekdayLabels.count
        return Double(cellCount - (columnIndex * weekdayLabels.count + row))
    }

    private struct HeatmapCellView: View {
        let cell: HeatmapCell

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: CornerRadius.chip)
            return shape
                .fill(cell.isFuture ? Color.clear : HeatmapPalette.color(level: cell.level))
                .overlay {
                    if cell.isToday {
                        shape.strokeBorder(Palette.ink, lineWidth: HeatmapGrid.todayLineWidth)
                    } else if cell.isFuture {
                        shape.strokeBorder(Palette.separator, lineWidth: HeatmapGrid.futureLineWidth)
                    }
                }
        }
    }
}
