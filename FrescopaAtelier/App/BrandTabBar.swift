import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, brew, shop, cafes, account

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .brew: "Brew"
        case .shop: "Shop"
        case .cafes: "Cafés"
        case .account: "Account"
        }
    }

    var icon: BrandIcon {
        switch self {
        case .home: .home
        case .brew: .brewCup
        case .shop: .bag
        case .cafes: .location
        case .account: .account
        }
    }
}

/// Five-tab bar from the design: translucent paper, hairline top border,
/// burgundy for the selected tab and ink-soft for the rest.
struct BrandTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = tab == selection
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 3) {
                        BrandIconView(icon: tab.icon, size: 24, weight: isSelected ? .medium : .regular)
                            .symbolVariant(isSelected ? .fill : .none)
                        Text(tab.title)
                            .textStyle(.tabLabel)
                    }
                    .foregroundStyle(isSelected ? Color.burgundy : Color.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                .accessibilityLabel(tab.title)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.paper.opacity(0.85))
                .overlay(alignment: .top) { Rectangle().fill(Color.line).frame(height: 1) }
                .ignoresSafeArea(edges: .bottom)
        }
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isTabBar)
    }
}

#Preview {
    @Previewable @State var tab = AppTab.home
    VStack {
        Spacer()
        BrandTabBar(selection: $tab)
    }
    .background(Color.paper)
}
