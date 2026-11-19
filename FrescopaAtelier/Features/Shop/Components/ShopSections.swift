import SwiftUI

/// Title, bag button and search field.
struct ShopHeader: View {
    @Binding var searchText: String
    let bagCount: Int
    var onOpenBag: () -> Void = {}

    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow("Shop")
                    Text("Beans, leaves & machines")
                        .textStyle(.greetingTitle)
                        .foregroundStyle(Color.burgundy)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: 8)
                BagButton(count: bagCount, action: onOpenBag)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.inkSoft)
                TextField("Search", text: $searchText, prompt: Text("Search coffee, tea, machines").foregroundStyle(Color.inkSoft.opacity(0.7)))
                    .font(BrandFont.body(15, relativeTo: .body))
                    .foregroundStyle(Color.ink)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Color.inkSoft)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(Capsule().fill(Color.paper2))
            .overlay(Capsule().strokeBorder(searchFocused ? Color.terracotta : Color.line, lineWidth: 1))
            .animation(Motion.quint, value: searchFocused)
        }
        .padding(.horizontal, Spacing.headingInset)
        .padding(.top, 14)
    }
}

struct BagButton: View {
    let count: Int
    /// Draw our own circle. Off inside navigation toolbars, which supply their own glass backing.
    var framed = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            BrandIconView(icon: .bag, size: 20)
                .foregroundStyle(Color.ink)
                .frame(width: framed ? 42 : 30, height: framed ? 42 : 30)
                .background(Circle().fill(framed ? Color.paper : .clear))
                .overlay(Circle().strokeBorder(framed ? Color.line : .clear, lineWidth: 1))
                .overlay(alignment: .topTrailing) {
                    if count > 0 {
                        Text("\(count)")
                            .font(BrandFont.body(10, weight: .bold, relativeTo: .caption2))
                            .foregroundStyle(Color.cream)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Capsule().fill(Color.terracotta))
                            .offset(x: 4, y: -2)
                            .contentTransition(.numericText())
                            .transition(.scale.combined(with: .opacity))
                    }
                }
        }
        .buttonStyle(.pressable)
        .animation(Motion.quint, value: count)
        .accessibilityLabel(count > 0 ? "Bag, \(count) items" : "Bag, empty")
    }
}

/// Dark hero for The Atelier, pulled live from the catalog.
struct FeaturedProductCard: View {
    let product: ShopProduct
    var onOpen: () -> Void = {}

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .bottom, spacing: 14) {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Bean-to-cup machine", color: .amber, weight: .regular)
                    Text(product.name)
                        .textStyle(.cardTitle)
                        .foregroundStyle(Color.cream)
                        .padding(.top, 6)
                    Text(product.summary)
                        .textStyle(.bodySmall)
                        .foregroundStyle(Color.creamSoft)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 6)
                    HStack(spacing: 10) {
                        Text(product.priceLabel)
                            .font(BrandFont.display(20, relativeTo: .title3))
                            .foregroundStyle(Color.cream)
                        if let option = product.options.first {
                            HStack(spacing: 4) {
                                ForEach(option.values) { value in
                                    Circle()
                                        .fill(FinishSwatch.color(for: value.title))
                                        .overlay(Circle().strokeBorder(Color.lineDark, lineWidth: 1))
                                        .frame(width: 14, height: 14)
                                }
                            }
                            .accessibilityLabel("\(option.values.count) finishes")
                        }
                    }
                    .padding(.top, 14)
                    HStack(spacing: 4) {
                        Text("Explore")
                        Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
                    }
                    .font(BrandFont.body(14, weight: .semibold, relativeTo: .subheadline))
                    .foregroundStyle(Color.amber)
                    .padding(.top, 12)
                }
                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    Color.charcoal
                    RadialGradient(colors: [Color.amber.opacity(0.22), .clear], center: .topTrailing, startRadius: 0, endRadius: 300)
                    Image(systemName: "cube")
                        .font(.system(size: 120, weight: .ultraLight))
                        .foregroundStyle(Color.cream.opacity(0.06))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .offset(x: 18, y: -10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.985))
        .environment(\.colorScheme, .dark)
        .padding(.horizontal, Spacing.screenInset)
    }
}

/// Category chips with a sort menu.
struct CategorySortBar: View {
    let categories: [ShopCategory]
    @Binding var category: ShopCategory?
    @Binding var sort: ShopSort

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: category == nil) { category = nil }
                    ForEach(categories) { item in
                        FilterChip(title: item.name, isSelected: category == item) {
                            category = category == item ? nil : item
                        }
                    }
                }
                .padding(.leading, Spacing.screenInset)
                .padding(.trailing, 8)
            }
            .scrollIndicators(.hidden)

            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(ShopSort.allCases) { Text($0.title).tag($0) }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(sort == .featured ? Color.ink : Color.cream)
                    .frame(width: 36, height: 34)
                    .background(Capsule().fill(sort == .featured ? Color.paper : Color.burgundy))
                    .overlay(Capsule().strokeBorder(sort == .featured ? Color.line : Color.burgundy, lineWidth: 1))
            }
            .accessibilityLabel("Sort, \(sort.title)")
            .padding(.trailing, Spacing.screenInset)
        }
        .sensoryFeedback(.selection, trigger: category)
        .sensoryFeedback(.selection, trigger: sort)
    }
}

/// Grid tile: image, name, summary, price and a quick-add button.
struct ProductTile: View {
    let product: ShopProduct
    var onAdd: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The box sets the size; the photo is an overlay so an aspect-filled image can't widen the tile.
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .overlay { ProductImage(product: product, width: 500) }
                .clipped()
                .overlay(alignment: .topLeading) {
                    if !product.inStock {
                        TagLabel(text: "Sold out").padding(8)
                    } else if !product.options.isEmpty {
                        TagLabel(text: "\(product.options[0].values.count) \(product.options[0].title.lowercased())es")
                            .padding(8)
                    }
                }

            VStack(alignment: .leading, spacing: 0) {
                Text(product.name)
                    .textStyle(.productTitle)
                    .foregroundStyle(Color.ink)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                Text(product.summary.isEmpty ? " " : product.summary)
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 3)
                HStack {
                    Text(product.priceLabel)
                        .textStyle(.price)
                        .foregroundStyle(Color.ink)
                    Spacer()
                    if product.inStock {
                        AddToBagButton(accessibilityName: product.name, action: onAdd)
                    }
                }
                .padding(.top, 10)
            }
            .padding(12)
        }
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
        .elevation(.sm)
        .contentShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

/// Shimmer-free skeleton tile shown while the first page loads.
struct ProductTileSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle().fill(Color.paper3).frame(height: 150)
            VStack(alignment: .leading, spacing: 8) {
                Capsule().fill(Color.paper3).frame(height: 12)
                Capsule().fill(Color.paper3).frame(width: 80, height: 10)
                Capsule().fill(Color.paper3).frame(width: 50, height: 14).padding(.top, 10)
            }
            .padding(12)
        }
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
        .accessibilityHidden(true)
    }
}

#Preview {
    let products = MockShopService.products
    return ScrollView {
        VStack(spacing: 20) {
            ShopHeader(searchText: .constant(""), bagCount: 2)
            FeaturedProductCard(product: products[0])
            CategorySortBar(categories: [.init(name: "Machines", path: "m"), .init(name: "Tea", path: "t")],
                            category: .constant(nil), sort: .constant(.featured))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(products) { ProductTile(product: $0) }
                ProductTileSkeleton()
            }
            .padding(.horizontal)
        }
    }
    .background(Color.paper)
}
