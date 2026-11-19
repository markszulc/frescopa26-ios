import SwiftUI

/// Section 1 — the connected machine and today's tuned cup (the primary daily job).
struct AtelierMachineCard: View {
    let machine: Machine
    let status: Machine.Status
    let recommendation: BrewRecommendation
    let brewTitle: String
    let isBrewing: Bool
    var onBrew: () -> Void = {}
    var onAdjust: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusRow

            Eyebrow(recommendation.eyebrow, color: .amber, weight: .regular)
                .padding(.top, 20)

            Text(recommendation.title)
                .textStyle(.cardTitle)
                .foregroundStyle(Color.cream)
                .padding(.top, 6)
                .accessibilityAddTraits(.isHeader)

            Text(recommendation.rationale)
                .textStyle(.bodySmall)
                .lineSpacing(3)
                .foregroundStyle(Color.creamSoft)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)

            actions
                .padding(.top, 18)

            MachineLevelsView(levels: machine.levels)
                .padding(.top, 16)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.lineDark).frame(height: 1)
                }
                .padding(.top, 18)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                Color.charcoal
                // Amber glow from the top-right corner.
                RadialGradient(
                    colors: [Color.amber.opacity(0.22), Color.amber.opacity(0)],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 300
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your Atelier")
    }

    private var statusRow: some View {
        HStack {
            HStack(spacing: 8) {
                StatusDot(status: status)
                Text("\(machine.name) · \(status.label)")
                    .textStyle(.caption)
                    .foregroundStyle(Color.cream)
                    .contentTransition(.opacity)
                    .animation(Motion.quint, value: status)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Eyebrow(machine.room, color: .creamSoft, size: 10, weight: .regular, trackingEm: 0.12)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button(action: onBrew) {
                HStack(spacing: 8) {
                    if isBrewing {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.cream)
                    }
                    Text(brewTitle)
                        .contentTransition(.opacity)
                }
                .animation(Motion.quint, value: brewTitle)
            }
            .buttonStyle(.pill(.primary, fullWidth: true))
            .disabled(isBrewing)
            .sensoryFeedback(.impact(weight: .medium), trigger: isBrewing) { _, new in new }
            .sensoryFeedback(.success, trigger: status) { _, new in new == .cupReady }

            Button("Adjust", action: onAdjust)
                .buttonStyle(.pill(.ghostOnDark))
        }
    }
}

/// Green "online" dot with a soft halo; pulses while brewing.
private struct StatusDot: View {
    let status: Machine.Status
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var color: Color {
        switch status {
        case .offline: .creamSoft
        case .brewing: .amber
        default: .statusOnline
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .background(
                Circle()
                    .fill(color.opacity(0.28))
                    .frame(width: 14, height: 14)
                    .scaleEffect(pulse ? 1.5 : 1)
                    .opacity(pulse ? 0 : 1)
            )
            .onChange(of: status, initial: true) { _, new in
                guard !reduceMotion else { return }
                if new == .brewing {
                    withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) { pulse = true }
                } else {
                    withAnimation(.default) { pulse = false }
                }
            }
            .accessibilityHidden(true)
    }
}

/// Water / Beans / Filter levels along the bottom of the machine card.
struct MachineLevelsView: View {
    let levels: Machine.Levels
    /// Below this, a level is highlighted in amber.
    var lowThreshold: Double = 0.25

    var body: some View {
        Grid(horizontalSpacing: 10) {
            GridRow {
                level("Water", levels.water)
                level("Beans", levels.beans)
                level("Filter", levels.filter)
            }
        }
    }

    private func level(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .textStyle(.meta)
                .foregroundStyle(Color.creamSoft)
            LevelBar(value: value, fill: value < lowThreshold ? .amber : .cream, track: .charcoal2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))) + Text(value < lowThreshold ? ", low" : ""))
    }
}

#Preview {
    let content = MockHomeService.sample()
    return AtelierMachineCard(
        machine: content.machine,
        status: .ready,
        recommendation: content.recommendation,
        brewTitle: "Brew now",
        isBrewing: false
    )
    .padding(16)
    .background(Color.paper)
}
