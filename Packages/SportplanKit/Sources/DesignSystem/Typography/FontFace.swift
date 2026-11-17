public enum FontFace: String, CaseIterable, Sendable {
    case unboundedMedium = "Unbounded-Medium"
    case unboundedSemiBold = "Unbounded-SemiBold"
    case onestRegular = "Onest-Regular"
    case onestMedium = "Onest-Medium"
    case onestSemiBold = "Onest-SemiBold"

    public var postScriptName: String {
        return rawValue
    }
}
