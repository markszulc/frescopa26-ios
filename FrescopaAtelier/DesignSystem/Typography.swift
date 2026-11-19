import SwiftUI
import CoreText

/// Fréscopa type system.
///
/// - **Schibsted Grotesk** — display & headlines (heavy, tight tracking).
/// - **Hanken Grotesk** — body, labels, and the "mono" role (uppercase + tracked eyebrows).
///
/// Both ship as variable fonts; SwiftUI's `.weight(_:)` drives the `wght` axis.
/// Every style is created with `relativeTo:` so it scales with Dynamic Type.
enum BrandFont {
    static let displayFamily = "Schibsted Grotesk"
    static let bodyFamily = "Hanken Grotesk"

    static func display(_ size: CGFloat, weight: Font.Weight = .heavy, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(displayFamily, size: size, relativeTo: style).weight(weight)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(bodyFamily, size: size, relativeTo: style).weight(weight)
    }

    /// Registers the bundled brand fonts with CoreText. Call once at launch.
    static func registerAll(bundle: Bundle = .main) {
        let urls = (bundle.urls(forResourcesWithExtension: "woff2", subdirectory: nil) ?? [])
            + (bundle.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
        for url in urls {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // Already-registered is benign (e.g. SwiftUI previews re-running init).
                #if DEBUG
                if let err = error?.takeRetainedValue() {
                    print("[BrandFont] Could not register \(url.lastPathComponent): \(err)")
                }
                #endif
            }
        }
    }
}

/// Named text styles taken directly from the design's inline styles.
enum TextStyle {
    case greetingTitle      // 30 / 800 display
    case cardTitle          // 26 / 800 display
    case bannerTitle        // 22 / 800 display
    case sectionTitle       // 21 / 800 display
    case insight            // 18 / 700 display
    case productTitle       // 15 / 700 display
    case price              // 15 / 700 display
    case bodyStrong         // 15 / 600
    case button             // 15 / 600
    case bodySmall          // 14 / 400
    case caption            // 13 / 400
    case label              // 12 / 500
    case meta               // 11 / 400
    case tabLabel           // 11 / 500

    var font: Font {
        switch self {
        case .greetingTitle: BrandFont.display(30, relativeTo: .largeTitle)
        case .cardTitle:     BrandFont.display(26, relativeTo: .title)
        case .bannerTitle:   BrandFont.display(22, relativeTo: .title2)
        case .sectionTitle:  BrandFont.display(21, relativeTo: .title3)
        case .insight:       BrandFont.display(18, weight: .bold, relativeTo: .headline)
        case .productTitle:  BrandFont.display(15, weight: .bold, relativeTo: .subheadline)
        case .price:         BrandFont.display(15, weight: .bold, relativeTo: .subheadline)
        case .bodyStrong:    BrandFont.body(15, weight: .semibold, relativeTo: .subheadline)
        case .button:        BrandFont.body(15, weight: .semibold, relativeTo: .subheadline)
        case .bodySmall:     BrandFont.body(14, relativeTo: .subheadline)
        case .caption:       BrandFont.body(13, relativeTo: .footnote)
        case .label:         BrandFont.body(12, weight: .medium, relativeTo: .caption)
        case .meta:          BrandFont.body(11, relativeTo: .caption2)
        case .tabLabel:      BrandFont.body(11, weight: .medium, relativeTo: .caption2)
        }
    }

    /// Display styles use -0.02em tracking.
    var tracking: CGFloat {
        switch self {
        case .greetingTitle: -0.6
        case .cardTitle: -0.52
        case .bannerTitle: -0.44
        case .sectionTitle: -0.42
        default: 0
        }
    }
}

extension View {
    func textStyle(_ style: TextStyle) -> some View {
        font(style.font).tracking(style.tracking)
    }
}
