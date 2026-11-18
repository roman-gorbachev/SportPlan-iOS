import SwiftUI

public struct PlateStack: View {
    private static let height: CGFloat = 44
    private static let plateSpacing: CGFloat = 2
    private static let collarSize = CGSize(width: 3, height: 16)
    private static let sleeveSize = CGSize(width: 12, height: 6)
    private static let collarRadius: CGFloat = 1
    private static let plateRadius: CGFloat = 2
    private static let outlineWidth: CGFloat = 0.5
    private static let plateWidths: [(minimumKilograms: Double, width: CGFloat)] = [
        (minimumKilograms: 25, width: 10),
        (minimumKilograms: 20, width: 8),
        (minimumKilograms: 15, width: 7),
        (minimumKilograms: 10, width: 6),
        (minimumKilograms: 5, width: 5),
        (minimumKilograms: 2.5, width: 4),
    ]
    private static let smallestPlateWidth: CGFloat = 3
    private static let plateHeights: [(minimumKilograms: Double, height: CGFloat)] = [
        (minimumKilograms: 10, height: 42),
        (minimumKilograms: 5, height: 32),
        (minimumKilograms: 2.5, height: 22),
    ]
    private static let smallestPlateHeight: CGFloat = 16

    private let plates: [PlateStackItem]

    public init(plates: [PlateStackItem]) {
        self.plates = plates
    }

    public var body: some View {
        return HStack(spacing: Self.plateSpacing) {
            RoundedRectangle(cornerRadius: Self.collarRadius)
                .fill(Palette.plateCollar)
                .frame(width: Self.collarSize.width, height: Self.collarSize.height)
            ForEach(Array(plates.enumerated()), id: \.offset) { _, plate in
                return RoundedRectangle(cornerRadius: Self.plateRadius)
                    .fill(Color(hex: plate.rgb))
                    .overlay {
                        RoundedRectangle(cornerRadius: Self.plateRadius)
                            .strokeBorder(Palette.separatorStrong, lineWidth: Self.outlineWidth)
                    }
                    .frame(width: Self.width(for: plate), height: Self.height(for: plate))
            }
            RoundedRectangle(cornerRadius: Self.collarRadius)
                .fill(Palette.plateSleeve)
                .frame(width: Self.sleeveSize.width, height: Self.sleeveSize.height)
        }
        .frame(height: Self.height)
    }

    private static func width(for plate: PlateStackItem) -> CGFloat {
        return plateWidths.first { entry in
            return plate.kilograms >= entry.minimumKilograms
        }?.width ?? smallestPlateWidth
    }

    private static func height(for plate: PlateStackItem) -> CGFloat {
        return plateHeights.first { entry in
            return plate.kilograms >= entry.minimumKilograms
        }?.height ?? smallestPlateHeight
    }
}

#Preview {
    FontRegistry.registerFonts()
    return VStack(alignment: .trailing, spacing: Spacing.m) {
        PlateStack(plates: [PlateStackItem(rgb: 0x1E8A4C, kilograms: 10)])
        PlateStack(plates: [PlateStackItem(rgb: 0x1F5FBF, kilograms: 20), PlateStackItem(rgb: 0xD7261E, kilograms: 2.5)])
        PlateStack(plates: [
            PlateStackItem(rgb: 0xD7261E, kilograms: 25),
            PlateStackItem(rgb: 0xF2C200, kilograms: 15),
            PlateStackItem(rgb: 0xFFFFFF, kilograms: 5),
            PlateStackItem(rgb: 0xA8A8A3, kilograms: 1.25),
        ])
    }
    .padding()
    .background(Palette.surface)
}
