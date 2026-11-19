import Foundation

public enum StandardPlates {
    private static let iwfSpecs: [(grams: Int, color: PlatePaletteColor)] = [
        (grams: 25_000, color: .red),
        (grams: 20_000, color: .blue),
        (grams: 15_000, color: .yellow),
        (grams: 10_000, color: .green),
        (grams: 5_000, color: .white),
        (grams: 2_500, color: .red),
        (grams: 1_250, color: .steel),
    ]

    public static func makeIWFSet() -> [Plate] {
        return iwfSpecs.map { spec in
            return Plate(id: UUID(), weight: Weight(grams: spec.grams), color: spec.color.color)
        }
    }
}
