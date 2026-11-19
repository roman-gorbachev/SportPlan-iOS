import DesignSystem
import SwiftUI
import WorkoutActivity

struct WorkoutIslandSymbol: View {
    private static let setSymbol = "dumbbell.fill"
    private static let restSymbol = "timer"
    private static let finishedSymbol = "checkmark"

    let state: WorkoutActivityDisplayState

    var body: some View {
        return Image(systemName: symbolName)
            .foregroundStyle(tint)
            .accessibilityHidden(true)
    }

    private var symbolName: String {
        switch state {
        case .set:
            return Self.setSymbol
        case .rest, .restOver:
            return Self.restSymbol
        case .finishedSets:
            return Self.finishedSymbol
        }
    }

    private var tint: Color {
        switch state {
        case .set:
            return Palette.textPrimary
        case .rest:
            return Palette.accent
        case .restOver, .finishedSets:
            return Palette.success
        }
    }
}
