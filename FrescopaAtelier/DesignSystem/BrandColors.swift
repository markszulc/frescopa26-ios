import SwiftUI

/// Fréscopa colour tokens.
///
/// Source of truth is the OKLCH palette in the Claude Design export
/// (`--burgundy`, `--terracotta`, …). Values below are the exact sRGB
/// conversions of those OKLCH coordinates, so names map 1:1 to the web tokens.
extension Color {
    // MARK: Brand
    static let burgundy        = Color(hex: 0x5F201E) // oklch(0.34 0.093 25)
    static let burgundyDeep    = Color(hex: 0x481311) // oklch(0.275 0.082 26)
    static let terracotta      = Color(hex: 0xBA6945) // oklch(0.605 0.116 44)
    static let terracottaDeep  = Color(hex: 0x9A4F35) // oklch(0.515 0.108 40)
    static let amber           = Color(hex: 0xEBAD54) // oklch(0.79 0.128 74)
    static let amberSoft       = Color(hex: 0xF0CD94) // oklch(0.865 0.083 80)
    static let teal            = Color(hex: 0x4D7A7F) // oklch(0.55 0.05 205)

    // MARK: Warm neutrals
    static let paper      = Color(hex: 0xF8F5EE)
    static let paper2     = Color(hex: 0xF3EDE3)
    static let paper3     = Color(hex: 0xECE2D6)
    static let sand       = Color(hex: 0xE4D6C7)
    static let line       = Color(hex: 0xD8CDC3)
    static let ink        = Color(hex: 0x2D221B)
    static let inkSoft    = Color(hex: 0x5A4D45)
    static let charcoal   = Color(hex: 0x211914)
    static let charcoal2  = Color(hex: 0x322721)
    static let lineDark   = Color(hex: 0x51453E)
    static let cream      = Color(hex: 0xF3ECE1)
    static let creamSoft  = Color(hex: 0xC4BBAD)

    // MARK: Functional
    /// "Ready" indicator on the machine card — oklch(0.78 0.15 150).
    static let statusOnline = Color(hex: 0x67D283)
    /// Warm shadow tint — oklch(0.3 0.03 50). Shadows are never neutral grey.
    static let shadowTint   = Color(hex: 0x3A2A20)
    /// Offer banner scrim base — oklch(0.18 0.02 45).
    static let scrim        = Color(hex: 0x190F0A)

    // MARK: Semantic aliases
    static let textHeading = burgundy
    static let textBody    = ink
    static let textMuted   = inkSoft
    static let textOnDark  = cream
    static let accent      = terracotta
}

extension ShapeStyle where Self == Color {
    static var burgundy: Color { .burgundy }
    static var terracotta: Color { .terracotta }
    static var terracottaDeep: Color { .terracottaDeep }
    static var amber: Color { .amber }
    static var ink: Color { .ink }
    static var inkSoft: Color { .inkSoft }
    static var cream: Color { .cream }
    static var creamSoft: Color { .creamSoft }
    static var paper: Color { .paper }
    static var paper2: Color { .paper2 }
    static var line: Color { .line }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
