import SwiftUI

/// Uppercase, tracked label — the design's "mono" role (Hanken Grotesk, not monospaced).
struct Eyebrow: View {
    let text: String
    var color: Color = .terracottaDeep
    var size: CGFloat = 11
    var weight: Font.Weight = .semibold
    /// Tracking in em (design uses 0.12–0.16em).
    var trackingEm: CGFloat = 0.16

    init(_ text: String, color: Color = .terracottaDeep, size: CGFloat = 11, weight: Font.Weight = .semibold, trackingEm: CGFloat = 0.16) {
        self.text = text
        self.color = color
        self.size = size
        self.weight = weight
        self.trackingEm = trackingEm
    }

    var body: some View {
        Text(text.uppercased())
            .font(BrandFont.body(size, weight: weight, relativeTo: .caption2))
            .tracking(size * trackingEm)
            .foregroundStyle(color)
            .accessibilityLabel(text)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        Eyebrow("Thursday 19 November")
        Eyebrow("94% match", size: 10, trackingEm: 0.12)
    }
    .padding()
    .background(Color.paper)
}
