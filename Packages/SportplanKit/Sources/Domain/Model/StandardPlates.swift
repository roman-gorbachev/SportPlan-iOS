import Foundation

public enum StandardPlates {
    private static let iwfSpecs: [(grams: Int, rgb: Int)] = [
        (grams: 25_000, rgb: 0xD7261E),
        (grams: 20_000, rgb: 0x1F5FBF),
        (grams: 15_000, rgb: 0xF2C200),
        (grams: 10_000, rgb: 0x1E8A4C),
        (grams: 5_000, rgb: 0xFFFFFF),
        (grams: 2_500, rgb: 0xD7261E),
        (grams: 1_250, rgb: 0xA8A8A3),
    ]

    public static func makeIWFSet() -> [Plate] {
        return iwfSpecs.map { spec in
            return Plate(id: UUID(), weight: Weight(grams: spec.grams), color: PlateColor(rgb: spec.rgb))
        }
    }
}
