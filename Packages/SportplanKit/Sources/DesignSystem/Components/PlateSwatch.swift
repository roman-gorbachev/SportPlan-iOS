import SwiftUI

public struct PlateSwatch: View {
    private static let diameter: CGFloat = 48
    private static let outlineWidth: CGFloat = 1
    private static let ringGap: CGFloat = 3
    private static let ringWidth: CGFloat = 2

    private let rgb: Int?
    private let isSelected: Bool

    public init(rgb: Int?, isSelected: Bool) {
        self.rgb = rgb
        self.isSelected = isSelected
    }

    public var body: some View {
        return Circle()
            .fill(fill)
            .overlay {
                Circle()
                    .strokeBorder(Palette.separatorStrong, lineWidth: Self.outlineWidth)
            }
            .overlay {
                if rgb == nil {
                    Image(systemName: "plus")
                        .appStyle(Typography.headline)
                        .foregroundStyle(Palette.textPrimary)
                }
            }
            .frame(width: Self.diameter, height: Self.diameter)
            .padding(Self.ringGap + Self.ringWidth)
            .overlay {
                if isSelected {
                    Circle()
                        .strokeBorder(Palette.ink, lineWidth: Self.ringWidth)
                }
            }
    }

    private var fill: Color {
        guard let rgb else {
            return Palette.surfaceSunken
        }
        return Color(hex: rgb)
    }
}

#Preview {
    return HStack {
        PlateSwatch(rgb: 0xD7261E, isSelected: true)
        PlateSwatch(rgb: 0xFFFFFF, isSelected: false)
        PlateSwatch(rgb: nil, isSelected: false)
    }
    .padding()
    .background(Palette.surface)
}
