import CoreText
import Foundation

public enum FontRegistry {
    private static let fontsDirectory = "Fonts"
    private static let fontExtension = "ttf"

    private static let registration: Void = {
        let urls = Bundle.module.urls(forResourcesWithExtension: fontExtension, subdirectory: fontsDirectory) ?? []
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    public static func registerFonts() {
        registration
    }
}
