import SwiftUI

/// Bean subscription: what's coming, when, and the three things people change most.
struct SubscriptionCard: View {
    let subscription: Subscription
    let nextDeliveryLine: String
    let busyAction: String?
    var onSkip: () -> Void = {}
    var onChange: () -> Void = {}
    var onPause: () -> Void = {}
    var onResume: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Your subscription")

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    BrandIconView(icon: .bean, size: 22)
                        .foregroundStyle(Color.burgundy)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Color.amber.opacity(0.3)))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(subscription.productName)
                            .textStyle(.bodyStrong)
                            .foregroundStyle(Color.ink)
                        Text("\(subscription.quantityLabel) · \(subscription.cadence.title.lowercased())")
                            .textStyle(.caption)
                            .foregroundStyle(Color.inkSoft)
                    }
                    Spacer()
                    Text(subscription.pricePerDelivery, format: .currency(code: "USD").presentation(.narrow).precision(.fractionLength(0)))
                        .textStyle(.price)
                        .foregroundStyle(Color.ink)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(subscription.isPaused ? Color.inkSoft : Color.statusOnline)
                        .frame(width: 6, height: 6)
                    Text(nextDeliveryLine)
                        .textStyle(.caption)
                        .foregroundStyle(Color.ink)
                        .contentTransition(.opacity)
                }
                .padding(.top, 14)

                HStack(spacing: 8) {
                    if subscription.isPaused {
                        actionButton("Resume", id: "resume", action: onResume)
                    } else {
                        actionButton("Skip next", id: "skip", action: onSkip)
                        actionButton("Pause", id: "pause", action: onPause)
                    }
                    actionButton("Change", id: "update", action: onChange)
                }
                .padding(.top, 14)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
            .padding(.horizontal, Spacing.screenInset)
            .padding(.top, 12)
            .animation(Motion.quint, value: subscription)
        }
    }

    private func actionButton(_ title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(busyAction == id ? 0 : 1)
                if busyAction == id { ProgressView().controlSize(.mini).tint(Color.burgundy) }
            }
        }
        .buttonStyle(.pill(.outline, height: 36, horizontalPadding: 14, fullWidth: true))
        .disabled(busyAction != nil)
    }
}

/// Sheet to change how often and how much coffee arrives.
struct SubscriptionEditor: View {
    let subscription: Subscription
    var onSave: (DeliveryCadence, Int) -> Void = { _, _ in }

    @State private var cadence: DeliveryCadence
    @State private var bags: Int
    @Environment(\.dismiss) private var dismiss

    init(subscription: Subscription, onSave: @escaping (DeliveryCadence, Int) -> Void = { _, _ in }) {
        self.subscription = subscription
        self.onSave = onSave
        _cadence = State(initialValue: subscription.cadence)
        _bags = State(initialValue: subscription.bags)
    }

    private var weeklyGrams: Double { Double(bags * subscription.bagSizeGrams) / Double(cadence.weeks) }
    /// ~18 g per cup.
    private var cupsPerDay: Double { weeklyGrams / 18 / 7 }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(subscription.productName)
                Text("How much, how often?")
                    .textStyle(.cardTitle)
                    .foregroundStyle(Color.burgundy)
                    .padding(.top, 6)

                Eyebrow("Delivery", color: .inkSoft, size: 10, trackingEm: 0.12)
                    .padding(.top, 24)
                VStack(spacing: 8) {
                    ForEach(DeliveryCadence.allCases) { option in
                        FilterChip(title: option.title, isSelected: cadence == option, expands: true) { cadence = option }
                    }
                }
                .padding(.top, 10)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Eyebrow("Bags per delivery", color: .inkSoft, size: 10, trackingEm: 0.12)
                        Text("\(bags) × \(subscription.bagSizeGrams) g")
                            .textStyle(.bodyStrong)
                            .foregroundStyle(Color.ink)
                    }
                    Spacer()
                    Stepper("Bags", value: $bags, in: 1...4)
                        .labelsHidden()
                }
                .padding(.top, 24)

                Text("Enough for about \(cupsPerDay, format: .number.precision(.fractionLength(1))) cups a day. \(Decimal(18 * bags), format: .currency(code: "USD").presentation(.narrow).precision(.fractionLength(0))) per delivery.")
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .padding(.top, 12)
                    .contentTransition(.numericText())
                    .animation(Motion.quint, value: bags)

                Spacer()

                Button("Save changes") {
                    onSave(cadence, bags)
                    dismiss()
                }
                .buttonStyle(DarkPrimaryPill())
                .disabled(cadence == subscription.cadence && bags == subscription.bags)
            }
            .padding(.horizontal, Spacing.headingInset)
            .padding(.vertical, Spacing.sm)
            .background(Color.paper)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundStyle(Color.burgundy)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sensoryFeedback(.selection, trigger: cadence)
        }
        .presentationDetents([.large])
        .presentationCornerRadius(Radius.xl)
        .presentationBackground(Color.paper)
    }
}

#Preview {
    let sub = MockAccountService.sample(now: .now).subscription
    return SubscriptionCard(subscription: sub, nextDeliveryLine: "Next delivery Tuesday 1 December", busyAction: nil)
        .padding(.vertical)
        .background(Color.paper)
}
