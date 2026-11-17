import SwiftUI

public struct TypeStyle: Sendable {
    public let face: FontFace
    public let size: CGFloat
    public let lineHeight: CGFloat
    public let relativeTo: Font.TextStyle
    public let usesTabularDigits: Bool

    public init(face: FontFace, size: CGFloat, lineHeight: CGFloat, relativeTo: Font.TextStyle, usesTabularDigits: Bool) {
        self.face = face
        self.size = size
        self.lineHeight = lineHeight
        self.relativeTo = relativeTo
        self.usesTabularDigits = usesTabularDigits
    }

    public var font: Font {
        let base = Font.custom(face.postScriptName, size: size, relativeTo: relativeTo)
        return usesTabularDigits ? base.monospacedDigit() : base
    }
}
