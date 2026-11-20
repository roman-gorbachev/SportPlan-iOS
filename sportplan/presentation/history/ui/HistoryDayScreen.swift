import DesignSystem
import Foundation
import SwiftUI

struct HistoryDayScreen: View {
    let data: HistoryDayUiData
    let onOpenWorkout: (UUID) -> Void

    var body: some View {
        return ScrollView {
            HistoryWorkoutList(items: data.items, onOpenWorkout: onOpenWorkout)
                .padding(.horizontal, Spacing.s)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.xl)
        }
        .background(Palette.background)
        .navigationTitle(data.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    FontRegistry.registerFonts()
    return NavigationStack {
        HistoryDayScreen(
            data: HistoryDayUiData(
                title: "Пятница, 13 ноября",
                items: [
                    HistoryWorkoutItem(id: UUID(), title: "Пт 13 · День C · Ноги и плечи", meta: "52 мин · 19 подходов", recordCount: 1, recordCountText: "1", accessibilityLabel: ""),
                    HistoryWorkoutItem(id: UUID(), title: "Пт 13 · Вне плана", meta: "20 мин · 6 подходов", recordCount: 0, recordCountText: "0", accessibilityLabel: ""),
                ]
            ),
            onOpenWorkout: { _ in }
        )
    }
}
