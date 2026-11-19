import SwiftUI

/// Dark hero card for today's tuned usual, mirroring the home machine card.
struct UsualBrewCard: View {
    let title: String
    let reason: String
    let summary: String
    let isBrewing: Bool
    let progress: BrewProgress?
    var onBrew: () -> Void = {}
    var onAdjust: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Your usual, tuned for today", color: .amber, weight: .regular)
            Text(title)
                .textStyle(.cardTitle)
                .foregroundStyle(Color.cream)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            Text(reason)
                .textStyle(.bodySmall)
                .lineSpacing(3)
                .foregroundStyle(Color.creamSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            Text(summary)
                .textStyle(.caption)
                .foregroundStyle(Color.cream)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.charcoal2))
                .overlay(Capsule().strokeBorder(Color.lineDark, lineWidth: 1))
                .padding(.top, 12)

            if let progress {
                VStack(alignment: .leading, spacing: 6) {
                    LevelBar(value: progress.fraction, fill: .amber, track: .charcoal2, height: 5)
                    Text(progress.stage.title + "…")
                        .textStyle(.meta)
                        .foregroundStyle(Color.creamSoft)
                        .contentTransition(.opacity)
                }
                .padding(.top, 16)
                .transition(.opacity)
            }

            HStack(spacing: 10) {
                Button(isBrewing ? "Brewing…" : "Brew now", action: onBrew)
                    .buttonStyle(.pill(.primary, fullWidth: true))
                    .disabled(isBrewing)
                Button("Adjust", action: onAdjust)
                    .buttonStyle(.pill(.ghostOnDark))
                    .disabled(isBrewing)
            }
            .padding(.top, 18)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                Color.charcoal
                RadialGradient(colors: [Color.amber.opacity(0.22), .clear], center: .topTrailing, startRadius: 0, endRadius: 300)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .environment(\.colorScheme, .dark)
        .animation(Motion.quint, value: isBrewing)
        .padding(.horizontal, Spacing.screenInset)
    }
}

#Preview {
    UsualBrewCard(title: "Flat white, a touch rounder.",
                  reason: "Cooler morning, early meeting.",
                  summary: "House blend · 18 g · 92° · oat at 60°",
                  isBrewing: true, progress: .init(stage: .extracting, fraction: 0.45))
        .padding(.vertical)
        .background(Color.paper)
}
