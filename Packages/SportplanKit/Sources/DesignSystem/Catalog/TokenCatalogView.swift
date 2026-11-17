import SwiftUI

struct TokenCatalogView: View {
    private static let swatchSize: CGFloat = 44

    private let colors: [(String, Color)] = [
        ("background", Palette.background),
        ("surface", Palette.surface),
        ("surfaceSunken", Palette.surfaceSunken),
        ("separator", Palette.separator),
        ("separatorStrong", Palette.separatorStrong),
        ("textPrimary", Palette.textPrimary),
        ("textSecondary", Palette.textSecondary),
        ("textTertiary", Palette.textTertiary),
        ("ink", Palette.ink),
        ("onInk", Palette.onInk),
        ("accent", Palette.accent),
        ("success", Palette.success),
        ("record", Palette.record),
        ("warmup", Palette.warmup),
        ("destructive", Palette.destructive),
    ]

    private let styles: [(String, TypeStyle)] = [
        ("numeralHero", Typography.numeralHero),
        ("numeralL", Typography.numeralL),
        ("numeralM", Typography.numeralM),
        ("numeralS", Typography.numeralS),
        ("largeTitle", Typography.largeTitle),
        ("title", Typography.title),
        ("headline", Typography.headline),
        ("body", Typography.body),
        ("callout", Typography.callout),
        ("footnote", Typography.footnote),
        ("caption", Typography.caption),
    ]

    var body: some View {
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                colorSection
                heatmapSection
                typeSection
            }
            .padding(Spacing.m)
        }
        .background(Palette.background)
    }

    private var colorSection: some View {
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            return ForEach(colors, id: \.0) { name, color in
                return HStack(spacing: Spacing.s) {
                    RoundedRectangle(cornerRadius: CornerRadius.chip)
                        .fill(color)
                        .stroke(Palette.separatorStrong)
                        .frame(width: Self.swatchSize, height: Self.swatchSize)
                    Text(verbatim: name)
                        .appStyle(Typography.callout)
                        .foregroundStyle(Palette.textPrimary)
                }
            }
        }
    }

    private var heatmapSection: some View {
        return HStack(spacing: Spacing.xxs) {
            return ForEach(Palette.heatmapLevels.indices, id: \.self) { index in
                return RoundedRectangle(cornerRadius: CornerRadius.chip)
                    .fill(Palette.heatmapLevels[index])
                    .frame(width: Self.swatchSize, height: Self.swatchSize)
            }
        }
    }

    private var typeSection: some View {
        return VStack(alignment: .leading, spacing: Spacing.s) {
            return ForEach(styles, id: \.0) { name, style in
                return VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(verbatim: style.usesTabularDigits ? "62,5 × 8" : "Жим лёжа")
                        .appStyle(style)
                        .foregroundStyle(Palette.textPrimary)
                    Text(verbatim: name)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
    }
}

#Preview("Light") {
    FontRegistry.registerFonts()
    return TokenCatalogView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FontRegistry.registerFonts()
    return TokenCatalogView()
        .preferredColorScheme(.dark)
}
