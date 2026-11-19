import SwiftUI

/// Short confirmation pill shown above the tab bar.
struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .textStyle(.caption)
            .foregroundStyle(Color.cream)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.charcoal))
            .elevation(.md)
            .padding(.horizontal, Spacing.md)
            .onAppear { UIAccessibility.post(notification: .announcement, argument: message) }
    }
}

#Preview {
    ToastView(message: "Skipped. We'll send the next one as usual.")
        .padding()
        .background(Color.paper)
}
