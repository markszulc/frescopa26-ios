import SwiftUI

/// Base press feedback for every tappable surface: a subtle 0.97 scale on the quint curve.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

/// Pill-shaped button in the brand's three treatments.
struct PillButtonStyle: ButtonStyle {
    enum Kind {
        /// Terracotta-deep fill, cream label — primary action on dark cards.
        case primary
        /// Hairline outline on dark surfaces.
        case ghostOnDark
        /// Burgundy outline on light surfaces.
        case outline
    }

    var kind: Kind
    var height: CGFloat = 48
    var horizontalPadding: CGFloat = 18
    var fullWidth = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height)
            .background {
                Capsule().fill(fill(pressed: configuration.isPressed))
            }
            .overlay {
                if let stroke {
                    Capsule().strokeBorder(stroke, lineWidth: 1)
                }
            }
            .contentShape(Capsule())
            .opacity(isEnabled ? 1 : 0.6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }

    private var font: Font {
        switch kind {
        case .primary: BrandFont.body(15, weight: .semibold, relativeTo: .subheadline)
        case .ghostOnDark: BrandFont.body(15, weight: .medium, relativeTo: .subheadline)
        case .outline: BrandFont.body(13, weight: .semibold, relativeTo: .footnote)
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary, .ghostOnDark: .cream
        case .outline: .burgundy
        }
    }

    private func fill(pressed: Bool) -> Color {
        switch kind {
        case .primary: pressed ? .burgundyDeep : .terracottaDeep
        case .ghostOnDark: pressed ? .charcoal2 : .clear
        case .outline: pressed ? .paper3 : .clear
        }
    }

    private var stroke: Color? {
        switch kind {
        case .primary: nil
        case .ghostOnDark: .lineDark
        case .outline: .burgundy
        }
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static func pill(_ kind: PillButtonStyle.Kind, height: CGFloat = 48, horizontalPadding: CGFloat = 18, fullWidth: Bool = false) -> PillButtonStyle {
        PillButtonStyle(kind: kind, height: height, horizontalPadding: horizontalPadding, fullWidth: fullWidth)
    }
}

/// Circular burgundy "+" used to add a product to the bag.
struct AddToBagButton: View {
    let accessibilityName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.cream)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.burgundy))
                // Expand the hit target to 44pt without changing the visual.
                .padding(6)
                .contentShape(Circle())
                .padding(-6)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Add \(accessibilityName) to bag")
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            Button("Brew now") {}.buttonStyle(.pill(.primary, fullWidth: true))
            Button("Adjust") {}.buttonStyle(.pill(.ghostOnDark))
        }
        .padding()
        .background(Color.charcoal)
        Button("Send now") {}.buttonStyle(.pill(.outline, height: 36, horizontalPadding: 14))
        AddToBagButton(accessibilityName: "Ethiopia Guji") {}
    }
    .padding()
    .background(Color.paper)
}
