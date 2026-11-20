import DesignSystem
import Foundation
import SwiftUI

struct HistoryWorkoutList: View {
    let items: [HistoryWorkoutItem]
    let onOpenWorkout: (UUID) -> Void

    var body: some View {
        return VStack(spacing: .zero) {
            ForEach(items) { item in
                HistoryWorkoutRow(item: item) {
                    onOpenWorkout(item.id)
                }
                if item.id != items.last?.id {
                    Divider()
                        .overlay(Palette.separator)
                        .padding(.leading, Spacing.m)
                }
            }
        }
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}
