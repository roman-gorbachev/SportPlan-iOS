import SwiftUI

public enum Typography {
    public static let numeralHero = TypeStyle(face: .unboundedSemiBold, size: 56, lineHeight: 60, relativeTo: .largeTitle, usesTabularDigits: true)
    public static let numeralL = TypeStyle(face: .unboundedSemiBold, size: 36, lineHeight: 40, relativeTo: .title, usesTabularDigits: true)
    public static let numeralM = TypeStyle(face: .unboundedSemiBold, size: 26, lineHeight: 30, relativeTo: .title2, usesTabularDigits: true)
    public static let numeralS = TypeStyle(face: .unboundedMedium, size: 17, lineHeight: 22, relativeTo: .headline, usesTabularDigits: true)

    public static let largeTitle = TypeStyle(face: .onestSemiBold, size: 34, lineHeight: 41, relativeTo: .largeTitle, usesTabularDigits: false)
    public static let title = TypeStyle(face: .onestSemiBold, size: 22, lineHeight: 28, relativeTo: .title2, usesTabularDigits: false)
    public static let headline = TypeStyle(face: .onestSemiBold, size: 17, lineHeight: 22, relativeTo: .headline, usesTabularDigits: false)
    public static let body = TypeStyle(face: .onestRegular, size: 17, lineHeight: 24, relativeTo: .body, usesTabularDigits: false)
    public static let callout = TypeStyle(face: .onestMedium, size: 15, lineHeight: 20, relativeTo: .callout, usesTabularDigits: false)
    public static let footnote = TypeStyle(face: .onestRegular, size: 13, lineHeight: 18, relativeTo: .footnote, usesTabularDigits: false)
    public static let caption = TypeStyle(face: .onestMedium, size: 12, lineHeight: 16, relativeTo: .caption, usesTabularDigits: false)
}
