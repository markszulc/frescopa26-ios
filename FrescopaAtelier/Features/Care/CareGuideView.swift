import SwiftUI

/// Step-by-step maintenance routine with machine cycles and a completion state.
struct CareGuideView: View {
    @State private var model: CareGuideModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: CareGuideModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer(minLength: 20)
            if model.isComplete { completion } else { stepCard }
            Spacer(minLength: 20)
            controls
        }
        .padding(.horizontal, Spacing.headingInset)
        .padding(.bottom, Spacing.sm)
        .background(Color.paper)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.isRunning)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(model.title)
                    .font(BrandFont.display(17, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(Color.ink)
            }
        }
        .animation(Motion.quint, value: model.index)
        .animation(Motion.quint, value: model.isComplete)
        .sensoryFeedback(.selection, trigger: model.index)
        .sensoryFeedback(.success, trigger: model.isComplete) { _, done in done }
        .onDisappear { model.cancel() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(model.isComplete ? "All done" : "Step \(model.index + 1) of \(model.steps.count)")
                Spacer()
                if let remaining = model.remainingLabel, !model.isComplete {
                    Text(remaining)
                        .font(BrandFont.body(12, weight: .medium, relativeTo: .caption))
                        .foregroundStyle(Color.inkSoft)
                        .contentTransition(.numericText())
                }
            }
            HStack(spacing: 6) {
                ForEach(model.steps) { step in
                    Capsule()
                        .fill(fill(for: step))
                        .frame(height: 5)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Progress")
            .accessibilityValue(Text(model.overallProgress, format: .percent.precision(.fractionLength(0))))
        }
        .padding(.top, 8)
    }

    private func fill(for step: CareStep) -> Color {
        let position = model.steps.firstIndex(of: step) ?? 0
        if model.isComplete || position < model.index { return .terracotta }
        if position == model.index { return model.isRunning ? .amber : .burgundy }
        return .paper3
    }

    private var stepCard: some View {
        let step = model.step
        return VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.amber.opacity(0.22))
                if let progress = model.cycleProgress {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.terracotta, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(3)
                        .animation(.linear(duration: 0.2), value: progress)
                }
                Image(systemName: step.systemImage)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Color.burgundy)
                    .symbolEffect(.pulse, isActive: model.isRunning && !reduceMotion)
            }
            .frame(width: 150, height: 150)

            VStack(spacing: 8) {
                Text(step.title)
                    .textStyle(.cardTitle)
                    .foregroundStyle(Color.burgundy)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(step.detail)
                    .textStyle(.bodySmall)
                    .lineSpacing(3)
                    .foregroundStyle(Color.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if step.isMachineCycle && model.isMachineBusy && !model.isRunning {
                Label("Finish your brew before starting this cycle.", systemImage: "exclamationmark.circle")
                    .textStyle(.caption)
                    .foregroundStyle(Color.terracottaDeep)
            }
        }
        .frame(maxWidth: .infinity)
        .id(step.id)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)))
    }

    private var completion: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color.cream)
                .frame(width: 100, height: 100)
                .background(Circle().fill(Color.burgundy))
            Text("\(model.title) complete")
                .textStyle(.cardTitle)
                .foregroundStyle(Color.burgundy)
                .multilineTextAlignment(.center)
            Text("The Atelier has reset its reminder. Your next cup will taste the difference.")
                .textStyle(.bodySmall)
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .transition(.scale(scale: 0.96).combined(with: .opacity))
    }

    @ViewBuilder
    private var controls: some View {
        if model.isComplete {
            Button("Done") { dismiss() }
                .buttonStyle(DarkPrimaryPill())
        } else {
            HStack(spacing: 10) {
                if model.isRunning {
                    Button("Stop") { model.cancel() }
                        .buttonStyle(.pill(.outline, height: 48, horizontalPadding: 22))
                } else if model.canGoBack {
                    Button("Back") { model.back() }
                        .buttonStyle(.pill(.outline, height: 48, horizontalPadding: 22))
                }
                Button {
                    model.primary()
                } label: {
                    HStack(spacing: 8) {
                        if model.isRunning { ProgressView().controlSize(.small).tint(Color.cream) }
                        Text(model.primaryTitle)
                    }
                }
                .buttonStyle(DarkPrimaryPill())
                .disabled(model.isRunning || (model.step.isMachineCycle && model.isMachineBusy))
            }
        }
    }
}

#Preview {
    let machine = MachineController(service: MockBrewService())
    return NavigationStack {
        CareGuideView(model: CareGuideModel(task: machine.care[0], machine: machine))
    }
}
