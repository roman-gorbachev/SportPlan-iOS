import SwiftUI

enum HeatmapPalette {
    static func color(level: Int) -> Color {
        let levels = Palette.heatmapLevels
        guard let first = levels.first, let last = levels.last else {
            return Palette.surfaceSunken
        }
        guard level > .zero else {
            return first
        }
        guard level < levels.count else {
            return last
        }
        return levels[level]
    }
}
