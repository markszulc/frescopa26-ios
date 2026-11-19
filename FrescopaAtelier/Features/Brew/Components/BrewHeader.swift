import SwiftUI

/// Top of the Brew tab: machine name, title, and a live status pill with levels.
struct BrewHeader: View {
    let machineName: String
    let status: Machine.Status
    let levels: Machine.Levels

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow("\(machineName) · Kitchen")
                Text("What are we brewing?")
                    .textStyle(.greetingTitle)
                    .foregroundStyle(Color.burgundy)
                    .accessibilityAddTraits(.isHeader)
            }
            MachineStatusPill(status: status, levels: levels)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.headingInset)
        .padding(.top, 14)
    }
}

/// "● Ready · Water 72% · Beans 18% low"
struct MachineStatusPill: View {
    let status: Machine.Status
    let levels: Machine.Levels

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(status == .brewing ? Color.amber : Color.statusOnline)
                    .frame(width: 7, height: 7)
                Text(status.label)
                    .foregroundStyle(Color.ink)
                    .contentTransition(.opacity)
            }
            divider
            level("Water", levels.water)
            divider
            level("Beans", levels.beans)
        }
        .font(BrandFont.body(12, weight: .medium, relativeTo: .caption))
        .padding(.horizontal, 12)
        .frame(minHeight: 32)
        .background(Capsule().fill(Color.paper2))
        .overlay(Capsule().strokeBorder(Color.line, lineWidth: 1))
        .animation(Motion.quint, value: status)
        .accessibilityElement(children: .combine)
    }

    private var divider: some View {
        Rectangle().fill(Color.line).frame(width: 1, height: 14)
    }

    private func level(_ title: String, _ value: Double) -> some View {
        HStack(spacing: 4) {
            Text(title).foregroundStyle(Color.inkSoft)
            Text(value, format: .percent.precision(.fractionLength(0)))
                .foregroundStyle(value < 0.25 ? Color.terracottaDeep : Color.ink)
                .contentTransition(.numericText())
        }
        .animation(Motion.quint, value: value)
    }
}

#Preview {
    BrewHeader(machineName: "The Atelier", status: .ready, levels: .init(water: 0.72, beans: 0.18, filter: 0.6))
        .background(Color.paper)
}
