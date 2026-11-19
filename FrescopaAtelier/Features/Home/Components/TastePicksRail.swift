import SwiftUI

/// Section 5 — taste-led product recommendations in a snapping horizontal rail.
struct TastePicksRail: View {
    let title: String
    let picks: [ProductPick]
    var onSeeAll: () -> Void = {}
    var onSelect: (ProductPick) -> Void = { _ in }
    var onAdd: (ProductPick) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: title, actionTitle: "See all", action: onSeeAll)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(picks) { pick in
                        ProductPickCard(pick: pick, onAdd: { onAdd(pick) })
                            .onTapGesture { onSelect(pick) }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, Spacing.screenInset)
                .padding(.top, 14)
                .padding(.bottom, 4)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
}

/// Heading row used by home sections: display title + trailing text link.
struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: () -> Void = {}

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .textStyle(.sectionTitle)
                .foregroundStyle(Color.burgundy)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle {
                Button(actionTitle, action: action)
                    .font(BrandFont.body(14, weight: .medium, relativeTo: .subheadline))
                    .foregroundStyle(Color.terracottaDeep)
                    .buttonStyle(.pressable)
            }
        }
        .padding(.horizontal, Spacing.headingInset)
    }
}

struct ProductPickCard: View {
    let pick: ProductPick
    var width: CGFloat = 158
    var onAdd: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProductArtwork(pick: pick)
                .frame(width: width, height: 118)
                .clipped()

            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(pick.matchLabel, size: 10, trackingEm: 0.12)
                Text(pick.title)
                    .textStyle(.productTitle)
                    .foregroundStyle(Color.ink)
                    .lineLimit(2, reservesSpace: true)
                    .padding(.top, 5)
                HStack {
                    Text(pick.price, format: .currency(code: pick.currencyCode).presentation(.narrow).precision(.fractionLength(0)))
                        .textStyle(.price)
                        .foregroundStyle(Color.ink)
                    Spacer()
                    AddToBagButton(accessibilityName: pick.title, action: onAdd)
                }
                .padding(.top, 10)
            }
            .padding(12)
        }
        .frame(width: width)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1)
        )
        .elevation(.sm)
        .contentShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

/// Product photo, or a warm branded placeholder until photography lands in the asset catalogue.
struct ProductArtwork: View {
    let pick: ProductPick

    var body: some View {
        if let name = pick.imageName, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFill()
                .accessibilityLabel(pick.imageDescription)
        } else {
            placeholder
                .accessibilityLabel(pick.imageDescription)
        }
    }

    private var palette: (Color, Color, String) {
        switch pick.kind {
        case .coffee: (.charcoal2, .terracottaDeep, "cup.and.saucer.fill")
        case .tea: (.terracottaDeep, .amber, "leaf.fill")
        case .juice: (.amber, .amberSoft, "drop.fill")
        }
    }

    private var placeholder: some View {
        let (from, to, symbol) = palette
        return ZStack {
            LinearGradient(colors: [from, to], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Color.cream.opacity(0.85))
        }
    }
}

#Preview {
    TastePicksRail(title: "Picked for your taste", picks: MockHomeService.sample().picks)
        .padding(.vertical)
        .background(Color.paper)
}
