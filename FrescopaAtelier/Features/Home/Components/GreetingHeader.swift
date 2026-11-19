import SwiftUI

/// Section 0 — date eyebrow, personal greeting and the notifications bell.
struct GreetingHeader: View {
    let dateLine: String
    let greeting: String
    let unreadCount: Int
    var onNotifications: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.xs) {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(dateLine)
                Text(greeting)
                    .textStyle(.greetingTitle)
                    .foregroundStyle(Color.burgundy)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 0)
            NotificationBellButton(unreadCount: unreadCount, action: onNotifications)
        }
        .padding(.horizontal, Spacing.headingInset)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }
}

struct NotificationBellButton: View {
    let unreadCount: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            BrandIconView(icon: .bell, size: 20)
                .foregroundStyle(Color.ink)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.paper))
                .overlay(Circle().strokeBorder(Color.line, lineWidth: 1))
                .overlay(alignment: .topTrailing) {
                    if unreadCount > 0 {
                        Circle()
                            .fill(Color.terracotta)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color.paper, lineWidth: 2))
                            .offset(x: -10, y: 9)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(unreadCount > 0 ? "Notifications, \(unreadCount) new" : "Notifications")
    }
}

#Preview {
    GreetingHeader(dateLine: "Thursday 19 November", greeting: "Good morning, Mark.", unreadCount: 1)
        .background(Color.paper)
}
