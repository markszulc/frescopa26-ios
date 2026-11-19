import SwiftUI

/// Shop tab: the live Fréscopa catalog from Adobe Commerce.
struct ShopView: View {
    @Bindable var model: ShopViewModel
    @State private var path: [ShopProduct] = []
    @State private var showsBag = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ShopHeader(searchText: $model.searchText, bagCount: model.bag.itemCount) { showsBag = true }

                    if let featured = model.featured, !model.isFiltering {
                        FeaturedProductCard(product: featured) { path.append(featured) }
                            .padding(.top, 20)
                            .transition(.opacity)
                    }

                    CategorySortBar(categories: model.categories, category: $model.category, sort: $model.sort)
                        .padding(.top, 20)

                    results
                }
                .animation(Motion.quint, value: model.isFiltering)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .background(Color.paper)
            .refreshable { await model.refresh() }
            .task { await model.load() }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ShopProduct.self) { product in
                ProductDetailView(model: ProductDetailModel(product: product, service: model.service), bag: model.bag) {
                    showsBag = true
                }
            }
        }
        .tint(Color.burgundy)
        .sheet(isPresented: $showsBag) {
            BagView(bag: model.bag)
        }
        .sensoryFeedback(.success, trigger: model.bag.addedCount)
    }

    @ViewBuilder
    private var results: some View {
        switch model.state {
        case .idle, .loading:
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in ProductTileSkeleton() }
            }
            .padding(.horizontal, Spacing.screenInset)
            .padding(.top, 16)
        case .failed(let message):
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Color.burgundy)
                Text(message)
                    .textStyle(.bodySmall)
                    .foregroundStyle(Color.inkSoft)
                    .multilineTextAlignment(.center)
                Button("Try again") { Task { await model.refresh() } }
                    .buttonStyle(.pill(.outline, height: 40))
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.lg)
        default:
            HStack {
                Eyebrow(model.resultsTitle, color: .inkSoft, size: 10, trackingEm: 0.12)
                Spacer()
                if model.isFiltering {
                    Button("Clear") { model.clearFilters() }
                        .font(BrandFont.body(13, weight: .medium, relativeTo: .footnote))
                        .foregroundStyle(Color.terracottaDeep)
                }
            }
            .padding(.horizontal, Spacing.headingInset)
            .padding(.top, 18)

            if model.products.isEmpty {
                Text("Nothing matches that yet. Try another search or category.")
                    .textStyle(.bodySmall)
                    .foregroundStyle(Color.inkSoft)
                    .padding(.horizontal, Spacing.headingInset)
                    .padding(.vertical, 30)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(model.products) { product in
                        Button { path.append(product) } label: {
                            ProductTile(product: product) {
                                if product.options.isEmpty { model.bag.add(product) } else { path.append(product) }
                            }
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.98))
                        .task { await model.loadMoreIfNeeded(after: product) }
                    }
                }
                .padding(.horizontal, Spacing.screenInset)
                .padding(.top, 12)
                .animation(Motion.quint, value: model.products.map(\.sku))

                if model.isLoadingMore {
                    ProgressView().tint(Color.burgundy).frame(maxWidth: .infinity).padding(.vertical, 20)
                }
            }

            Text("Live catalog from frescopacoffee.com")
                .font(BrandFont.body(11, relativeTo: .caption2))
                .foregroundStyle(Color.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        }
    }
}

#Preview {
    ShopView(model: ShopViewModel(service: MockShopService(), bag: BagStore()))
}
