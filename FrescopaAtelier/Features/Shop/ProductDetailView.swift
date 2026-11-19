import SwiftUI

/// Product page: image, price, options, quantity, add to bag and details.
struct ProductDetailView: View {
    @State private var model: ProductDetailModel
    let bag: BagStore
    var onOpenBag: () -> Void = {}

    @State private var justAdded = false

    init(model: ProductDetailModel, bag: BagStore, onOpenBag: @escaping () -> Void = {}) {
        _model = State(initialValue: model)
        self.bag = bag
        self.onOpenBag = onOpenBag
    }

    private var product: ShopProduct { model.displayProduct }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .overlay { ProductImage(product: product, width: 900) }
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                    .padding(.horizontal, Spacing.screenInset)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(product.inStock ? "In stock · SKU \(product.sku)" : "Sold out · SKU \(product.sku)",
                            color: product.inStock ? .terracottaDeep : .inkSoft)
                    Text(product.name)
                        .textStyle(.greetingTitle)
                        .foregroundStyle(Color.burgundy)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                        .accessibilityAddTraits(.isHeader)
                    Text(product.priceLabel)
                        .font(BrandFont.display(22, relativeTo: .title2))
                        .foregroundStyle(Color.ink)
                        .padding(.top, 6)
                    if !product.summary.isEmpty {
                        Text(product.summary)
                            .textStyle(.bodySmall)
                            .lineSpacing(3)
                            .foregroundStyle(Color.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                    }

                    if let option = model.option {
                        HStack {
                            Eyebrow(option.title, color: .inkSoft, size: 10, trackingEm: 0.12)
                            Spacer()
                            Text(model.selectedOption?.title ?? "Choose")
                                .font(BrandFont.body(13, weight: .semibold, relativeTo: .footnote))
                                .foregroundStyle(Color.ink)
                        }
                        .padding(.top, 22)
                        HStack(spacing: 10) {
                            ForEach(option.values) { value in
                                FinishSwatch(value: value, isSelected: model.selectedOption == value, size: 34) {
                                    model.selectedOption = value
                                }
                            }
                        }
                        .padding(.top, 10)
                        .sensoryFeedback(.selection, trigger: model.selectedOption)
                    }

                    HStack(spacing: 12) {
                        QuantityStepper(quantity: $model.quantity, range: 1...20)
                        Button {
                            bag.add(product, option: model.selectedOption, quantity: model.quantity)
                            withAnimation(Motion.quint) { justAdded = true }
                            Task {
                                try? await Task.sleep(for: .seconds(1.6))
                                withAnimation(Motion.quint) { justAdded = false }
                            }
                        } label: {
                            Label(justAdded ? "Added" : "Add to bag", systemImage: justAdded ? "checkmark" : "bag")
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(DarkPrimaryPill())
                        .disabled(!model.canAdd)
                    }
                    .padding(.top, 24)

                    if bag.itemCount > 0 {
                        Button(action: onOpenBag) {
                            HStack {
                                Text("\(bag.itemCount) in your bag · \(bag.subtotal.formatted)")
                                Spacer()
                                Text("View bag")
                                Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
                            }
                            .font(BrandFont.body(13, weight: .semibold, relativeTo: .footnote))
                            .foregroundStyle(Color.terracottaDeep)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.pressable)
                        .transition(.opacity)
                    }

                    details
                }
                .padding(.horizontal, Spacing.headingInset)
                .padding(.top, 20)
                .padding(.bottom, Spacing.lg)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.paper)
        .task { await model.load() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Color.paper, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                BagButton(count: bag.itemCount, framed: false, action: onOpenBag)
            }
        }
    }

    @ViewBuilder
    private var details: some View {
        switch model.state {
        case .loading:
            ProgressView().tint(Color.burgundy).frame(maxWidth: .infinity).padding(.top, 30)
        case .failed:
            Text("Details couldn't load. You can still add this to your bag.")
                .textStyle(.caption)
                .foregroundStyle(Color.inkSoft)
                .padding(.top, 24)
        case .loaded:
            if let detail = model.detail {
                if !detail.description.isEmpty && detail.description != product.summary {
                    Text("About")
                        .textStyle(.sectionTitle)
                        .foregroundStyle(Color.burgundy)
                        .padding(.top, 28)
                    Text(detail.description)
                        .textStyle(.bodySmall)
                        .lineSpacing(4)
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                }
                if !detail.facts.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(detail.facts, id: \.label) { fact in
                            HStack {
                                Text(fact.label).foregroundStyle(Color.inkSoft)
                                Spacer()
                                Text(fact.value).foregroundStyle(Color.ink)
                            }
                            .textStyle(.bodySmall)
                            .padding(.vertical, 12)
                            if fact.label != detail.facts.last?.label { Rectangle().fill(Color.line).frame(height: 1) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
                    .padding(.top, 20)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(model: ProductDetailModel(product: MockShopService.products[0], service: MockShopService()),
                          bag: BagStore())
    }
}
