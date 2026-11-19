import SwiftUI

/// Fade + rise on first appearance (the web design's `.reveal`), staggered by `delay`.
/// Falls back to fully visible when Reduce Motion is on.
struct RevealModifier: ViewModifier {
    var delay: Double

    @State private var isIn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isIn || reduceMotion ? 1 : 0)
            .offset(y: isIn || reduceMotion ? 0 : 22)
            .onAppear {
                guard !isIn else { return }
                withAnimation(Motion.expo.delay(delay)) { isIn = true }
            }
    }
}

extension View {
    func reveal(delay: Double = 0) -> some View {
        modifier(RevealModifier(delay: delay))
    }
}
