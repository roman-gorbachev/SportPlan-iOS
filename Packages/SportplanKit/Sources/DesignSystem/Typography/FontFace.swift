public enum FontFace: String, CaseIterable, Sendable {
    case sofiaSansCondensedMedium = "SofiaSansCondensed-Medium"
    case sofiaSansCondensedSemiBold = "SofiaSansCondensed-SemiBold"
    case onestRegular = "Onest-Regular"
    case onestMedium = "Onest-Medium"
    case onestSemiBold = "Onest-SemiBold"

    public var postScriptName: String {
        return rawValue
    }
}
