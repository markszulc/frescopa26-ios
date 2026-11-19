import SwiftUI

/// Full-screen brewing view: progress ring, machine stages, then a cup rating.
struct BrewProgressView: View {
    let machine: MachineController
    let summary: String
    /// Rating already given to the finished cup, if any.
    let rating: Int?
    var onCancel: () -> Void = {}
    var onRate: (Int) -> Void = { _ in }
    var onDone: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var steam = false

    private var order: BrewOrder? { machine.currentOrder ?? machine.lastCompleted }
    private var isReady: Bool { if case .ready = machine.phase { true } else { false } }
    private var failure: String? { if case .failed(let message) = machine.phase { message } else { nil } }

    var body: some View {
        ZStack {
            Color.charcoal.ignoresSafeArea()
            RadialGradient(colors: [Color.amber.opacity(0.18), .clear], center: .top, startRadius: 0, endRadius: 420)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Eyebrow(isReady ? "Cup ready" : (failure == nil ? "The Atelier is brewing" : "Brew stopped"),
                        color: .amber, weight: .regular)
                    .padding(.top, 24)
                Text(order?.title ?? "")
                    .textStyle(.greetingTitle)
                    .foregroundStyle(Color.cream)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                Text(summary)
                    .textStyle(.caption)
                    .foregroundStyle(Color.creamSoft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)

                Spacer(minLength: 24)
                ring
                Spacer(minLength: 24)

                if let failure {
                    Text(failure)
                        .textStyle(.bodySmall)
                        .foregroundStyle(Color.creamSoft)
                        .multilineTextAlignment(.center)
                } else if isReady {
                    VStack(spacing: 12) {
                        Text("How was it?")
                            .textStyle(.insight)
                            .foregroundStyle(Color.cream)
                        BeanRating(rating: rating, size: 28, onRate: onRate)
                        Text("Your ratings tune tomorrow's usual.")
                            .textStyle(.caption)
                            .foregroundStyle(Color.creamSoft)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else if let order {
                    stageList(order)
                }

                Spacer(minLength: 24)

                Group {
                    if isReady || failure != nil {
                        Button("Done", action: onDone)
                            .buttonStyle(.pill(.primary, fullWidth: true))
                    } else {
                        Button("Stop brewing", action: onCancel)
                            .buttonStyle(.pill(.ghostOnDark, fullWidth: true))
                    }
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, Spacing.md)
        }
        .environment(\.colorScheme, .dark)
        // Light status-bar text over the dark canvas while this cover is up.
        .preferredColorScheme(.dark)
        .animation(Motion.quint, value: isReady)
        .sensoryFeedback(.success, trigger: isReady) { _, new in new }
        .sensoryFeedback(.impact(weight: .light), trigger: machine.progress?.stage)
    }

    private var ring: some View {
        let fraction = isReady ? 1 : (machine.progress?.fraction ?? 0)
        return ZStack {
            Circle().stroke(Color.charcoal2, lineWidth: 10)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.amber, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: fraction)
            VStack(spacing: 6) {
                Image(systemName: isReady ? "checkmark" : (order?.drink.systemImage ?? "cup.and.saucer"))
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.cream)
                    .offset(y: steam && !isReady ? -2 : 0)
                    .contentTransition(.symbolEffect(.replace))
                Text(fraction, format: .percent.precision(.fractionLength(0)))
                    .font(BrandFont.display(22, relativeTo: .title2))
                    .foregroundStyle(Color.cream)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: 220, height: 220)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever()) { steam = true }
        }
        .accessibilityElement()
        .accessibilityLabel("Brew progress")
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }

    private func stageList(_ order: BrewOrder) -> some View {
        let stages = BrewStage.stages(for: order.drink)
        let current = machine.progress?.stage
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(stages, id: \.self) { stage in
                let isDone = current.map { stage < $0 } ?? false
                let isCurrent = stage == current
                HStack(spacing: 10) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : (isCurrent ? "circle.dotted" : "circle"))
                        .foregroundStyle(isDone || isCurrent ? Color.amber : Color.lineDark)
                        .symbolEffect(.rotate, isActive: isCurrent && !reduceMotion)
                    Text(stage.title)
                        .textStyle(.bodySmall)
                        .foregroundStyle(isCurrent ? Color.cream : (isDone ? Color.creamSoft : Color.lineDark))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 40)
        .animation(Motion.quint, value: current)
    }
}
