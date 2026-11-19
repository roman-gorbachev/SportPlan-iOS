import SwiftUI

public struct PlatePreview: View {
    private static let cardHeight: CGFloat = 150
    private static let spacing: CGFloat = 3
    private static let collarSize = CGSize(width: 6, height: 34)
    private static let sleeveSize = CGSize(width: 110, height: 12)
    private static let barRadius: CGFloat = 2
    private static let plateRadius: CGFloat = 4
    private static let outlineWidth: CGFloat = 1
    private static let plateSizes: [(minimumKilograms: Double, size: CGSize)] = [
        (minimumKilograms: 20, size: CGSize(width: 20, height: 118)),
        (minimumKilograms: 10, size: CGSize(width: 16, height: 118)),
        (minimumKilograms: 5, size: CGSize(width: 14, height: 92)),
        (minimumKilograms: 2.5, size: CGSize(width: 12, height: 72)),
    ]
    private static let smallestPlateSize = CGSize(width: 10, height: 56)

    private let plate: PlateStackItem

    public init(plate: PlateStackItem) {
        self.plate = plate
    }

    public var body: some View {
        let plateSize = Self.size(for: plate.kilograms)
        return HStack(spacing: Self.spacing) {
            RoundedRectangle(cornerRadius: Self.barRadius)
                .fill(Palette.plateCollar)
                .frame(width: Self.collarSize.width, height: Self.collarSize.height)
            RoundedRectangle(cornerRadius: Self.plateRadius)
                .fill(Color(hex: plate.rgb))
                .overlay {
                    RoundedRectangle(cornerRadius: Self.plateRadius)
                        .strokeBorder(Palette.separatorStrong, lineWidth: Self.outlineWidth)
                }
                .frame(width: plateSize.width, height: plateSize.height)
            RoundedRectangle(cornerRadius: Self.barRadius)
                .fill(Palette.plateSleeve)
                .frame(width: Self.sleeveSize.width, height: Self.sleeveSize.height)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.cardHeight)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private static func size(for kilograms: Double) -> CGSize {
        return plateSizes.first { entry in
            return kilograms >= entry.minimumKilograms
        }?.size ?? smallestPlateSize
    }
}

#Preview {
    return VStack(spacing: Spacing.m) {
        PlatePreview(plate: PlateStackItem(rgb: 0xD7261E, kilograms: 25))
        PlatePreview(plate: PlateStackItem(rgb: 0xFFFFFF, kilograms: 5))
    }
    .padding()
    .background(Palette.background)
}
