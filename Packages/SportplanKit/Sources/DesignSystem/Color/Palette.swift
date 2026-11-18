import SwiftUI

public enum Palette {
    public static let background = Color(light: 0xF3F2EF, dark: 0x111214)
    public static let surface = Color(light: 0xFFFFFF, dark: 0x1C1D20)
    public static let surfaceSunken = Color(light: 0xEAE9E5, dark: 0x26272B)

    public static let separator = Color(light: 0xE4E3DF, dark: 0x2E2F33)
    public static let separatorStrong = Color(light: 0xCFCEC8, dark: 0x45464B)

    public static let textPrimary = Color(light: 0x151515, dark: 0xF2F1EE)
    public static let textSecondary = Color(light: 0x5E5E5A, dark: 0xA3A29C)
    public static let textTertiary = Color(light: 0x6E6E69, dark: 0x8A8984)

    public static let ink = Color(light: 0x151515, dark: 0xF2F1EE)
    public static let onInk = Color(light: 0xFFFFFF, dark: 0x111214)

    public static let accent = Color(light: 0x1F5FBF, dark: 0x6A9BEA)

    public static let success = Color(light: 0x157A3B, dark: 0x3DB36E)
    public static let record = Color(hex: 0xF2C200)
    public static let onRecord = Color(hex: 0x151515)
    public static let warmup = Color(light: 0x5E5E5A, dark: 0xA3A29C)
    public static let destructive = Color(light: 0xC42019, dark: 0xFF6B5E)
    public static let plateCollar = Color(light: 0x8C8C87, dark: 0x6F6F6B)
    public static let plateSleeve = Color(light: 0xB5B4AF, dark: 0x4A4A47)

    public static let heatmapLevels: [Color] = [
        Color(light: 0xEAE9E5, dark: 0x26272B),
        Color(light: 0xB9CDEE, dark: 0x284A80),
        Color(light: 0x7FA5E3, dark: 0x2F64BC),
        Color(light: 0x3F74CC, dark: 0x4A7FD6),
        Color(light: 0x1A4FA3, dark: 0x6A9BEA),
    ]
}
