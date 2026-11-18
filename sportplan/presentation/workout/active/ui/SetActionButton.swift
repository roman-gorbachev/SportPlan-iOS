import DesignSystem
import SwiftUI

struct SetActionButton: View {
    private static let size: CGFloat = 48
    private static let ringWidth: CGFloat = 2

    let state: SetRowState
    let isTimed: Bool
    let action: () -> Void

    var body: some View {
        return Button(action: action) {
            return ZStack {
                if isFilled {
                    Circle()
                        .fill(Palette.ink)
                } else {
                    Circle()
                        .strokeBorder(ringColor, lineWidth: Self.ringWidth)
                }
                if let iconName {
                    Image(systemName: iconName)
                        .appStyle(Typography.headline)
                        .foregroundStyle(isFilled ? Palette.onInk : Palette.textPrimary)
                }
            }
            .frame(width: Self.size, height: Self.size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(state == .completed ? .isSelected : [])
    }

    private var isFilled: Bool {
        return state == .completed || state == .running
    }

    private var ringColor: Color {
        return state == .current ? Palette.ink : Palette.separatorStrong
    }

    private var iconName: String? {
        switch state {
        case .completed:
            return "checkmark"
        case .running:
            return "stop.fill"
        case .planned, .current:
            return isTimed ? "play.fill" : nil
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .completed:
            return String(localized: "workout.set.completed")
        case .running:
            return String(localized: "workout.set.stopStopwatch")
        case .planned, .current:
            return isTimed ? String(localized: "workout.set.startStopwatch") : String(localized: "workout.set.complete")
        }
    }
}
