import SwiftUI

/// Spacing scale (`--space-*`) plus the screen-level insets used by the app home.
enum Spacing {
    static let xxxs: CGFloat = 4
    static let xxs: CGFloat = 8
    static let xs: CGFloat = 12
    static let sm: CGFloat = 16
    static let md: CGFloat = 24
    static let lg: CGFloat = 40

    /// Horizontal inset for cards on the home screen.
    static let screenInset: CGFloat = 16
    /// Horizontal inset for section headings (slightly deeper than cards).
    static let headingInset: CGFloat = 20
}

/// Corner radius scale (`--r-*`).
enum Radius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 14
    static let lg: CGFloat = 22
    static let xl: CGFloat = 32
    static let tile: CGFloat = 18
}

/// Warm, soft elevation (`--shadow-*`). Each level is two stacked shadows.
enum Elevation {
    case sm, md, lg
}

extension View {
    func elevation(_ level: Elevation) -> some View {
        let tint = Color.shadowTint
        return Group {
            switch level {
            case .sm:
                self.shadow(color: tint.opacity(0.06), radius: 1, y: 1)
                    .shadow(color: tint.opacity(0.05), radius: 4, y: 2)
            case .md:
                self.shadow(color: tint.opacity(0.07), radius: 7, y: 4)
                    .shadow(color: tint.opacity(0.08), radius: 17, y: 14)
            case .lg:
                self.shadow(color: tint.opacity(0.10), radius: 17, y: 14)
                    .shadow(color: tint.opacity(0.13), radius: 40, y: 34)
            }
        }
    }
}

/// Motion tokens. Long, eased curves — quintic & expo, no bounce.
enum Motion {
    /// cubic-bezier(0.22, 1, 0.36, 1)
    static let quint = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.35)
    /// cubic-bezier(0.16, 1, 0.3, 1)
    static let expo = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.9)
    static let press = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.25)
}
