import SwiftUI

public struct PlateGlyph: View {
    private static let slotSize = CGSize(width: 28, height: 40)
    private static let radius: CGFloat = 2
    private static let outlineWidth: CGFloat = 1
    private static let widths: [(minimumKilograms: Double, width: CGFloat)] = [
        (minimumKilograms: 25, width: 9),
        (minimumKilograms: 20, width: 8),
        (minimumKilograms: 15, width: 7),
        (minimumKilograms: 10, width: 6),
        (minimumKilograms: 5, width: 5),
    ]
    private static let smallestWidth: CGFloat = 4
    private static let heights: [(minimumKilograms: Double, height: CGFloat)] = [
        (minimumKilograms: 10, height: 36),
        (minimumKilograms: 5, height: 28),
        (minimumKilograms: 2.5, height: 22),
    ]
    private static let smallestHeight: CGFloat = 18

    private let plate: PlateStackItem

    public init(plate: PlateStackItem) {
        self.plate = plate
    }

    public var body: some View {
        return RoundedRectangle(cornerRadius: Self.radius)
            .fill(Color(hex: plate.rgb))
            .overlay {
                RoundedRectangle(cornerRadius: Self.radius)
                    .strokeBorder(Palette.separatorStrong, lineWidth: Self.outlineWidth)
            }
            .frame(width: Self.width(for: plate.kilograms), height: Self.height(for: plate.kilograms))
            .frame(width: Self.slotSize.width, height: Self.slotSize.height)
            .accessibilityHidden(true)
    }

    private static func width(for kilograms: Double) -> CGFloat {
        return widths.first { entry in
            return kilograms >= entry.minimumKilograms
        }?.width ?? smallestWidth
    }

    private static func height(for kilograms: Double) -> CGFloat {
        return heights.first { entry in
            return kilograms >= entry.minimumKilograms
        }?.height ?? smallestHeight
    }
}

#Preview {
    return HStack {
        PlateGlyph(plate: PlateStackItem(rgb: 0xD7261E, kilograms: 25))
        PlateGlyph(plate: PlateStackItem(rgb: 0xFFFFFF, kilograms: 5))
        PlateGlyph(plate: PlateStackItem(rgb: 0xA8A8A3, kilograms: 1.25))
    }
    .padding()
    .background(Palette.surface)
}
