import SwiftUI

/// Thin rounded progress track used for machine levels and flavour bars.
struct LevelBar: View {
    /// 0...1
    var value: Double
    var fill: Color
    var track: Color
    var height: CGFloat = 5

    @State private var shown: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(fill)
                    .frame(width: proxy.size.width * min(max(shown, 0), 1))
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
        .onAppear { animate(to: value) }
        .onChange(of: value) { _, new in animate(to: new) }
        .accessibilityHidden(true)
    }

    private func animate(to target: Double) {
        if reduceMotion {
            shown = target
        } else {
            withAnimation(Motion.expo.delay(0.15)) { shown = target }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        LevelBar(value: 0.72, fill: .cream, track: .charcoal2)
        LevelBar(value: 0.18, fill: .amber, track: .charcoal2)
        LevelBar(value: 0.64, fill: .terracotta, track: .paper3, height: 6)
    }
    .padding()
    .background(Color.charcoal)
}
