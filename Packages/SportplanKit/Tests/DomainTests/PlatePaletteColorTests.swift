import Domain
import Testing

struct PlatePaletteColorTests {
    private static let paletteSize = 7
    private static let customRGB = 0x123456

    @Test func hasSevenDistinctColors() {
        let colors = PlatePaletteColor.allCases.map(\.color)
        #expect(colors.count == Self.paletteSize)
        #expect(Set(colors).count == Self.paletteSize)
    }

    @Test func recognizesPaletteColor() {
        #expect(PlatePaletteColor(color: PlatePaletteColor.steel.color) == .steel)
    }

    @Test func doesNotRecognizeCustomColor() {
        #expect(PlatePaletteColor(color: PlateColor(rgb: Self.customRGB)) == nil)
    }

    @Test func standardPlatesUsePaletteColors() {
        #expect(StandardPlates.makeIWFSet().allSatisfy { plate in
            return PlatePaletteColor(color: plate.color) != nil
        })
    }
}
