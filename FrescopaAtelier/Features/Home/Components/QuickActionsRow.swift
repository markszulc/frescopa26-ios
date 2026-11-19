import SwiftUI

/// Section 2 — four shortcut tiles.
struct QuickActionsRow: View {
    var actions: [QuickAction] = QuickAction.defaults
    var onSelect: (QuickAction.Destination) -> Void = { _ in }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(actions) { action in
                QuickActionTile(action: action) { onSelect(action.destination) }
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Spacing.screenInset)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quick actions")
    }
}

struct QuickActionTile: View {
    let action: QuickAction
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 7) {
                BrandIconView(icon: action.icon, size: 22)
                    .foregroundStyle(Color.burgundy)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                            .fill(Color.paper2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                            .strokeBorder(Color.line, lineWidth: 1)
                    )
                Text(action.title)
                    .textStyle(.label)
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.pressable)
    }
}

extension QuickAction {
    static let defaults: [QuickAction] = [
        QuickAction(title: "Brew menu", icon: .brewCup, destination: .brewMenu),
        QuickAction(title: "Reorder", icon: .reorder, destination: .reorder),
        QuickAction(title: "Care", icon: .care, destination: .care),
        QuickAction(title: "Cafés", icon: .location, destination: .cafes),
    ]
}

#Preview {
    QuickActionsRow()
        .padding(.vertical)
        .background(Color.paper)
}
