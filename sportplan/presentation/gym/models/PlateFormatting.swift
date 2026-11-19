import DesignSystem
import Domain
import Foundation

enum PlateFormatting {
    static func weightText(_ weight: Weight) -> String {
        return String(localized: "plate.weight \(WeightFormatting.kilograms(weight))")
    }

    static func colorName(_ color: PlateColor) -> String {
        return PlatePaletteColor(color: color)?.title ?? String(localized: "plate.color.customName")
    }

    static func stackItem(_ plate: Plate) -> PlateStackItem {
        return PlateStackItem(rgb: plate.color.rgb, kilograms: plate.weight.kilograms)
    }
}
