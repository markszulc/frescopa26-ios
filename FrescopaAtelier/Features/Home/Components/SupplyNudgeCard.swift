import SwiftUI

/// Section 3 — contextual supplies nudge (shown when beans run low).
struct SupplyNudgeCard: View {
    let headline: String
    let detail: String
    let actionTitle: String
    let isComplete: Bool
    let isWorking: Bool
    var onAction: () -> Void = {}

    var body: some View {
        HStack(spacing: 14) {
            BrandIconView(icon: .bean, size: 22)
                .foregroundStyle(Color.burgundy)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        // color-mix(amber 30%, paper)
                        .fill(Color.amber.opacity(0.30))
                        .background(Color.paper, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(headline)
                    .textStyle(.bodyStrong)
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .contentTransition(.opacity)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button(action: onAction) {
                ZStack {
                    Text(actionTitle).opacity(isWorking ? 0 : 1)
                    if isWorking {
                        ProgressView().controlSize(.mini).tint(Color.burgundy)
                    }
                }
                .contentTransition(.opacity)
            }
            .buttonStyle(.pill(.outline, height: 36, horizontalPadding: 14))
            .disabled(isComplete || isWorking)
            .sensoryFeedback(.success, trigger: isComplete) { _, new in new }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1)
        )
        .animation(Motion.quint, value: detail)
        .padding(.horizontal, Spacing.screenInset)
    }
}

#Preview {
    VStack(spacing: 16) {
        SupplyNudgeCard(headline: "About 6 cups of House blend left",
                        detail: "Next delivery Tue 1 Dec. Want it sooner?",
                        actionTitle: "Send now", isComplete: false, isWorking: false)
        SupplyNudgeCard(headline: "About 6 cups of House blend left",
                        detail: "Arriving tomorrow, Fri 20 Nov.",
                        actionTitle: "Done", isComplete: true, isWorking: false)
    }
    .padding(.vertical)
    .background(Color.paper)
}
