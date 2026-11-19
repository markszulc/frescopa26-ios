import SwiftUI

/// Recent orders with delivery status.
struct RecentOrdersSection: View {
    let orders: [OrderSummary]
    let relativeDate: (Date) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Orders")
            VStack(spacing: 0) {
                ForEach(orders) { order in
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(order.title)
                                .textStyle(.bodyStrong)
                                .foregroundStyle(Color.ink)
                                .lineLimit(1)
                            Text("#\(order.id) · \(relativeDate(order.date))")
                                .textStyle(.caption)
                                .foregroundStyle(Color.inkSoft)
                        }
                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(order.total, format: .currency(code: "USD").presentation(.narrow).precision(.fractionLength(0)))
                                .textStyle(.price)
                                .foregroundStyle(Color.ink)
                            OrderStatusTag(status: order.status)
                        }
                    }
                    .padding(.vertical, 12)
                    .accessibilityElement(children: .combine)
                    if order.id != orders.last?.id {
                        Rectangle().fill(Color.line).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, Spacing.headingInset)
            .padding(.top, 4)
        }
    }
}

struct OrderStatusTag: View {
    let status: OrderSummary.Status

    var body: some View {
        Text(status.rawValue.uppercased())
            .font(BrandFont.body(9, weight: .bold, relativeTo: .caption2))
            .tracking(1)
            .foregroundStyle(status == .delivered ? Color.inkSoft : Color.charcoal)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(status == .delivered ? Color.paper3 : Color.amber))
    }
}

/// Notification toggles, account links and sign-out.
struct AccountSettingsSection: View {
    @Binding var notifications: NotificationPreferences
    var onSignOut: () -> Void = {}

    @State private var confirmsSignOut = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Notifications")
            VStack(spacing: 0) {
                toggle("Brew reminders", "A nudge when your usual is ready to tune.", $notifications.brewReminders)
                divider
                toggle("Delivery updates", "When beans ship and arrive.", $notifications.deliveryUpdates)
                divider
                toggle("Café events", "Classes and cuppings near you.", $notifications.cafeEvents)
                divider
                toggle("Members' offers", "First looks at new single origins.", $notifications.offers)
            }
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
            .padding(.horizontal, Spacing.screenInset)
            .padding(.top, 12)

            SectionHeader(title: "Settings")
                .padding(.top, 28)
            VStack(spacing: 0) {
                link("Payment & addresses", "creditcard")
                divider
                link("Linked machines", "cube")
                divider
                link("Privacy & data", "hand.raised")
                divider
                link("Help & support", "questionmark.bubble")
            }
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
            .padding(.horizontal, Spacing.screenInset)
            .padding(.top, 12)

            Button("Sign out") { confirmsSignOut = true }
                .buttonStyle(.pill(.outline, height: 44, fullWidth: true))
                .padding(.horizontal, Spacing.screenInset)
                .padding(.top, 24)
                .confirmationDialog("Sign out of Fréscopa?", isPresented: $confirmsSignOut, titleVisibility: .visible) {
                    Button("Sign out", role: .destructive, action: onSignOut)
                } message: {
                    Text("Your machine keeps brewing your usual; you'll need to sign in to change it.")
                }

            Text("Fréscopa \(Bundle.main.appVersion)")
                .font(BrandFont.body(11, relativeTo: .caption2))
                .foregroundStyle(Color.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
        }
    }

    private var divider: some View { Rectangle().fill(Color.line).frame(height: 1) }

    private func toggle(_ title: String, _ detail: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).textStyle(.bodyStrong).foregroundStyle(Color.ink)
                Text(detail).textStyle(.caption).foregroundStyle(Color.inkSoft)
            }
        }
        .tint(Color.terracotta)
        .padding(.vertical, 12)
    }

    private func link(_ title: String, _ icon: String) -> some View {
        NavigationLink(value: AccountRoute.settings(title)) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 22)
                    .foregroundStyle(Color.burgundy)
                Text(title)
                    .textStyle(.bodyStrong)
                    .foregroundStyle(Color.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkSoft.opacity(0.6))
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }
}

enum AccountRoute: Hashable {
    case settings(String)
}

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            VStack(spacing: 28) {
                RecentOrdersSection(orders: MockAccountService.sample(now: .now).orders, relativeDate: { _ in "2 days ago" })
                AccountSettingsSection(notifications: .constant(NotificationPreferences()))
            }
            .padding(.vertical)
        }
        .background(Color.paper)
    }
}
