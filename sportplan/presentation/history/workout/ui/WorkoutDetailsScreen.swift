import DesignSystem
import Foundation
import SwiftUI

struct WorkoutDetailsScreen: View {
    private static let headerCollapseOffset: CGFloat = 60

    let data: WorkoutDetailsUiData
    let onOpenExercise: (UUID) -> Void
    let onDismissDeleteError: () -> Void

    @State private var isHeaderScrolledAway = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                header
                stats
                ForEach(data.exercises) { item in
                    return WorkoutDetailsExerciseCard(item: item, onOpenExercise: onOpenExercise)
                }
                if let note = data.note {
                    noteCard(note)
                }
            }
            .padding(.horizontal, Spacing.s)
            .padding(.bottom, Spacing.xl)
        }
        .background(Palette.background)
        .navigationTitle(isHeaderScrolledAway ? data.title : "")
        .navigationBarTitleDisplayMode(.inline)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            return geometry.contentOffset.y + geometry.contentInsets.top > Self.headerCollapseOffset
        } action: { _, isScrolledAway in
            isHeaderScrolledAway = isScrolledAway
        }
        .alert(
            String(localized: "history.details.delete.error"),
            isPresented: Binding(get: { return data.isShowingDeleteError }, set: { isPresented in
                if !isPresented {
                    onDismissDeleteError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        }
    }

    private var header: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(data.meta)
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
            Text(data.title)
                .appStyle(Typography.largeTitle)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
    }

    private var stats: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.xs))
        return layout {
            WorkoutDetailsStatTile(
                title: String(localized: "history.details.duration"),
                value: data.durationValue,
                unit: String(localized: "history.details.minutes"),
                isHighlighted: false
            )
            WorkoutDetailsStatTile(
                title: String(localized: "history.details.sets"),
                value: data.setCountValue,
                unit: nil,
                isHighlighted: false
            )
            WorkoutDetailsStatTile(
                title: String(localized: "history.details.records"),
                value: data.recordCountValue,
                unit: nil,
                isHighlighted: data.hasRecords
            )
        }
    }

    private func noteCard(_ note: String) -> some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(String(localized: "history.details.note"))
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
            Text(note)
                .appStyle(Typography.body)
                .foregroundStyle(Palette.textPrimary)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
        .accessibilityElement(children: .combine)
    }
}

private enum WorkoutDetailsPreviewData {
    static var data: WorkoutDetailsUiData {
        return WorkoutDetailsUiData(
            meta: "Пт 13 ноября · 18:05–18:57 · День C",
            title: "Ноги и плечи",
            durationValue: "52",
            setCountValue: "19",
            recordCountValue: "1",
            hasRecords: true,
            exercises: [
                WorkoutDetailsExerciseItem(
                    id: UUID(),
                    exerciseId: UUID(),
                    name: "Присед",
                    goal: "4 × 5",
                    sets: [
                        WorkoutDetailsSetItem(id: UUID(), number: "1", value: "60 × 8", isWarmup: true, isRecord: false, accessibilityLabel: ""),
                        WorkoutDetailsSetItem(id: UUID(), number: "2", value: "100 × 5", isWarmup: false, isRecord: false, accessibilityLabel: ""),
                        WorkoutDetailsSetItem(id: UUID(), number: "3", value: "102,5 × 5", isWarmup: false, isRecord: true, accessibilityLabel: ""),
                    ]
                ),
                WorkoutDetailsExerciseItem(
                    id: UUID(),
                    exerciseId: UUID(),
                    name: "Планка",
                    goal: "2 подхода",
                    sets: [
                        WorkoutDetailsSetItem(id: UUID(), number: "1", value: "1:30", isWarmup: false, isRecord: false, accessibilityLabel: ""),
                    ]
                ),
            ],
            note: "Колено не беспокоило",
            isShowingDeleteError: false
        )
    }
}

#Preview {
    FontRegistry.registerFonts()
    return NavigationStack {
        WorkoutDetailsScreen(data: WorkoutDetailsPreviewData.data, onOpenExercise: { _ in }, onDismissDeleteError: {})
    }
}
