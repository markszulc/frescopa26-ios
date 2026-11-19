import SwiftUI

/// Stand-in for screens that are designed but not yet built.
struct ComingSoonView: View {
    let title: String
    var icon: BrandIcon = .brewCup

    var body: some View {
        VStack(spacing: Spacing.sm) {
            BrandIconView(icon: icon, size: 44, weight: .light)
                .foregroundStyle(Color.burgundy)
            Text(title)
                .textStyle(.sectionTitle)
                .foregroundStyle(Color.burgundy)
            Text("This part of the Atelier is still being crafted.")
                .textStyle(.bodySmall)
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper)
    }
}

#Preview {
    ComingSoonView(title: "Shop", icon: .bag)
}
