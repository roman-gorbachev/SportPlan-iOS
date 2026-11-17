import CoreText
import Testing
@testable import DesignSystem

struct FontRegistryTests {
    private static let probeSize: CGFloat = 17

    @Test(arguments: FontFace.allCases)
    func registersBundledFace(face: FontFace) {
        FontRegistry.registerFonts()
        let font = CTFontCreateWithName(face.postScriptName as CFString, Self.probeSize, nil)
        let resolvedName = CTFontCopyPostScriptName(font) as String
        #expect(resolvedName == face.postScriptName)
    }

    @Test func providesFiveHeatmapLevels() {
        #expect(Palette.heatmapLevels.count == 5)
    }
}
