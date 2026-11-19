import SwiftUI

/// "The menu" — category chips over a two-column grid of drinks.
struct DrinkMenuSection: View {
    let drinks: [Drink]
    @Binding var category: DrinkCategory?
    var onSelect: (Drink) -> Void = { _ in }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow("Brew menu")
                Text("Everything the Atelier pours")
                    .textStyle(.sectionTitle)
                    .foregroundStyle(Color.burgundy)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, Spacing.headingInset)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: category == nil) { category = nil }
                    ForEach(DrinkCategory.allCases) { item in
                        FilterChip(title: item.title, isSelected: category == item) {
                            category = category == item ? nil : item
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenInset)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 14)
            .sensoryFeedback(.selection, trigger: category)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(drinks) { drink in
                    Button { onSelect(drink) } label: { DrinkCard(drink: drink) }
                        .buttonStyle(PressableButtonStyle(scale: 0.98))
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .padding(.horizontal, Spacing.screenInset)
            .padding(.top, 14)
            .animation(Motion.quint, value: drinks.map(\.id))
        }
    }
}

struct DrinkCard: View {
    let drink: Drink

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: drink.systemImage)
                    .font(.system(size: 19))
                    .foregroundStyle(Color.burgundy)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(drink.isCold ? Color.teal.opacity(0.16) : Color.amber.opacity(0.30))
                    )
                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkSoft.opacity(0.7))
            }
            Text(drink.name)
                .textStyle(.productTitle)
                .foregroundStyle(Color.ink)
                .padding(.top, 12)
            Text(drink.summary)
                .textStyle(.caption)
                .foregroundStyle(Color.inkSoft)
                .lineLimit(3, reservesSpace: true)
                .multilineTextAlignment(.leading)
                .padding(.top, 3)
            Text("\(drink.volumeML) ml · \(BrewTime.label(drink.brewSeconds))")
                .font(BrandFont.body(11, weight: .medium, relativeTo: .caption2))
                .foregroundStyle(Color.terracottaDeep)
                .padding(.top, 10)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
        .elevation(.sm)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens brew settings")
    }
}

enum BrewTime {
    /// 28 → "28s", 180 → "3 min"
    static func label(_ seconds: Int) -> String {
        seconds < 90 ? "\(seconds)s" : "\(Int((Double(seconds) / 60).rounded())) min"
    }
}

#Preview {
    DrinkMenuSection(drinks: MockBrewService.drinks, category: .constant(nil))
        .padding(.vertical)
        .background(Color.paper)
}
