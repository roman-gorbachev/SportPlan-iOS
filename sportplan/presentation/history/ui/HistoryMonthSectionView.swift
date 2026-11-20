import DesignSystem
import Foundation
import SwiftUI

struct HistoryMonthSectionView: View {
    let section: HistoryMonthSection
    let onOpenWorkout: (UUID) -> Void

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            ListSectionHeader(title: section.title)
                .textCase(.uppercase)
                .padding(.horizontal, Spacing.xs)
                .padding(.top, Spacing.xs)
                .accessibilityAddTraits(.isHeader)
            HistoryWorkoutList(items: section.items, onOpenWorkout: onOpenWorkout)
        }
    }
}
