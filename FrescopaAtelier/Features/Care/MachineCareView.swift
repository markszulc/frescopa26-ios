import SwiftUI

/// Machine care: health at a glance, supplies, the maintenance schedule with guided
/// routines, and a few habits that keep the Atelier tasting its best.
struct MachineCareView: View {
    let machine: MachineController
    /// Opens straight into this routine (e.g. Account's "Start descale").
    var startWith: CareTask.ID?
    var onOrderBeans: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var activeTask: CareTask?
    @State private var refilled = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow("The Atelier · Kitchen")
                        Text("Machine care")
                            .textStyle(.greetingTitle)
                            .foregroundStyle(Color.burgundy)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .padding(.horizontal, Spacing.headingInset)

                    MachineHealthCard(health: machine.health, urgent: machine.urgentCare,
                                      isBrewing: machine.isBrewing) { task in activeTask = task }
                        .padding(.top, 18)

                    SectionHeader(title: "Supplies").padding(.top, 28)
                    SuppliesCard(levels: machine.levels,
                                 onRefillWater: { machine.refill(.water); refilled += 1 },
                                 onOrderBeans: { dismiss(); onOrderBeans() },
                                 onReplaceFilter: { activeTask = machine.care.first { $0.id == "filter" } })
                        .padding(.top, 12)

                    SectionHeader(title: "Care schedule").padding(.top, 28)
                    VStack(spacing: 0) {
                        ForEach(machine.care) { task in
                            CareScheduleRow(task: task) { activeTask = task }
                            if task.id != machine.care.last?.id { Rectangle().fill(Color.line).frame(height: 1) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
                    .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
                    .padding(.horizontal, Spacing.screenInset)
                    .padding(.top, 12)

                    SectionHeader(title: "Good habits").padding(.top, 28)
                    CareTipsRail().padding(.top, 12)
                }
                .padding(.top, 4)
                .padding(.bottom, Spacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(Color.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundStyle(Color.burgundy)
                }
            }
            .navigationDestination(item: $activeTask) { task in
                CareGuideView(model: CareGuideModel(task: task, machine: machine))
            }
            .onAppear {
                if let startWith, activeTask == nil {
                    activeTask = machine.care.first { $0.id == startWith }
                }
            }
        }
        .tint(Color.burgundy)
        .presentationCornerRadius(Radius.xl)
        .presentationBackground(Color.paper)
        .sensoryFeedback(.success, trigger: refilled)
    }
}

extension CareTask: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Dark summary card: health ring plus the one thing to do next.
struct MachineHealthCard: View {
    let health: Double
    let urgent: CareTask?
    let isBrewing: Bool
    var onStart: (CareTask) -> Void = { _ in }

    private var verdict: String {
        switch health {
        case 0.75...: "In great shape"
        case 0.45...: "Doing well"
        default: "Needs a little love"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 18) {
                ZStack {
                    Circle().stroke(Color.charcoal2, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: health)
                        .stroke(health < 0.45 ? Color.amber : Color.statusOnline,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(health, format: .percent.precision(.fractionLength(0)))
                        .font(BrandFont.display(20, relativeTo: .title3))
                        .foregroundStyle(Color.cream)
                        .contentTransition(.numericText())
                }
                .frame(width: 84, height: 84)
                .animation(Motion.expo, value: health)

                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow("Machine health", color: .amber, weight: .regular)
                    Text(verdict)
                        .textStyle(.bannerTitle)
                        .foregroundStyle(Color.cream)
                        .contentTransition(.opacity)
                    Text(urgent.map { "\($0.title) · \($0.dueIn.lowercased())" } ?? "Nothing due. Enjoy your coffee.")
                        .textStyle(.caption)
                        .foregroundStyle(Color.creamSoft)
                }
            }
            .accessibilityElement(children: .combine)

            if let urgent {
                Button("Start \(urgent.title.lowercased())") { onStart(urgent) }
                    .buttonStyle(.pill(.primary, fullWidth: true))
                    .disabled(isBrewing)
            }
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
        .padding(.horizontal, Spacing.screenInset)
        .animation(Motion.quint, value: urgent?.id)
    }
}

/// Water, beans and filter with the action each one needs.
struct SuppliesCard: View {
    let levels: Machine.Levels
    var onRefillWater: () -> Void = {}
    var onOrderBeans: () -> Void = {}
    var onReplaceFilter: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            row("Water tank", "drop.fill", levels.water, action: levels.water > 0.95 ? nil : "I've refilled it", onRefillWater)
            divider
            row("Bean hopper", "circle.grid.2x2.fill", levels.beans, action: "Order beans", onOrderBeans)
            divider
            row("Water filter", "line.3.horizontal.decrease.circle.fill", levels.filter,
                action: levels.filter > 0.95 ? nil : "Replace", onReplaceFilter)
        }
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
        .padding(.horizontal, Spacing.screenInset)
        .animation(Motion.quint, value: levels)
    }

    private var divider: some View { Rectangle().fill(Color.line).frame(height: 1) }

    private func row(_ title: String, _ icon: String, _ value: Double, action: String?, _ perform: @escaping () -> Void) -> some View {
        let low = value < 0.25
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(low ? Color.terracottaDeep : Color.burgundy)
                    .frame(width: 20)
                Text(title).textStyle(.bodyStrong).foregroundStyle(Color.ink)
                Spacer()
                Text(value, format: .percent.precision(.fractionLength(0)))
                    .font(BrandFont.body(13, weight: .semibold, relativeTo: .footnote))
                    .foregroundStyle(low ? Color.terracottaDeep : Color.inkSoft)
                    .contentTransition(.numericText())
            }
            LevelBar(value: value, fill: low ? .amber : .terracotta, track: .paper3, height: 5)
            if let action {
                Button(action, action: perform)
                    .font(BrandFont.body(13, weight: .semibold, relativeTo: .footnote))
                    .foregroundStyle(Color.terracottaDeep)
                    .buttonStyle(.pressable)
            }
        }
        .padding(.vertical, 14)
    }
}

struct CareScheduleRow: View {
    let task: CareTask
    var onStart: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: task.systemImage)
                .font(.system(size: 17))
                .foregroundStyle(task.isDueSoon ? Color.terracottaDeep : Color.burgundy)
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(task.isDueSoon ? Color.amber.opacity(0.35) : Color.paper))
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title).textStyle(.bodyStrong).foregroundStyle(Color.ink)
                Text(task.dueIn)
                    .textStyle(.caption)
                    .foregroundStyle(task.isDueSoon ? Color.terracottaDeep : Color.inkSoft)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 8)
            Button(task.isDueSoon ? "Start" : "Run now", action: onStart)
                .buttonStyle(.pill(task.isDueSoon ? .outline : .outline, height: 34, horizontalPadding: 14))
        }
        .padding(.vertical, 12)
        .animation(Motion.quint, value: task.remaining)
    }
}

/// Small tips that keep the machine tasting good.
struct CareTipsRail: View {
    private let tips: [(String, String, String)] = [
        ("drop", "Use filtered water", "Softer water means sweeter shots and fewer descales."),
        ("tray", "Empty the tray daily", "A quick rinse keeps the grounds bin fresh."),
        ("shippingbox", "Keep beans airtight", "Close the hopper lid; light and air dull the flavour."),
        ("thermometer.medium", "Warm your cup", "A pre-heated cup holds the crema longer."),
    ]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(tips, id: \.1) { icon, title, detail in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 17))
                            .foregroundStyle(Color.burgundy)
                        Text(title).textStyle(.productTitle).foregroundStyle(Color.ink)
                        Text(detail)
                            .textStyle(.caption)
                            .foregroundStyle(Color.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(width: 180, alignment: .topLeading)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, Spacing.screenInset)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    MachineCareView(machine: MachineController(service: MockBrewService()))
}
