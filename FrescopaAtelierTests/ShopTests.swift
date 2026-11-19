import Foundation
import Testing
@testable import FrescopaAtelier

private final class BundleToken {}

struct CommerceDecodingTests {
    /// Real `products(skus:)` response captured from the Fréscopa Commerce endpoint.
    private func fixture() throws -> [ShopProduct] {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "commerce-products", withExtension: "json"))
        struct Envelope: Decodable { let data: ProductsResponse }
        let envelope = try JSONDecoder().decode(Envelope.self, from: Data(contentsOf: url))
        return envelope.data.products.map(\.model)
    }

    @Test func decodesSimpleProductWithImage() throws {
        let blend = try #require(try fixture().first { $0.sku == "COF-MB" })
        #expect(blend.name == "Morning Blend")
        #expect(blend.price == Money(amount: 10, currency: "USD"))
        #expect(blend.priceLabel == "$10")
        #expect(!blend.summary.contains("<p>"))
        let image = try #require(blend.imageURL(width: 400)?.absoluteString)
        #expect(image.hasSuffix("/as/COF-MB.jpg?quality=80&width=400"))
        #expect(blend.family == .coffee)
    }

    @Test func decodesConfigurableProductOptions() throws {
        let atelier = try #require(try fixture().first { $0.sku == "CSM6001" })
        #expect(atelier.price.amount == 2199)
        #expect(atelier.options.first?.title == "Finish")
        #expect(atelier.options.first?.values.map(\.title) == ["Cream", "Charcoal", "Terracotta"])
        #expect(atelier.family == .machine)
        #expect(atelier.imageURL == nil)
    }

    @Test func stripsHTML() {
        #expect(HTMLText.plain("<p>Hello &amp; welcome</p><p>Second</p>") == "Hello & welcome\n\nSecond")
        #expect(HTMLText.plain("Line<br/>break") == "Line\nbreak")
    }

    @Test func formatsMoney() {
        #expect(Money(amount: Decimal(string: "3.99")!, currency: "USD").formatted == "$3.99")
        #expect(Money(amount: 2199, currency: "USD").formatted == "$2,199")
    }
}

@MainActor
struct BagStoreTests {
    @Test func addingMergesLinesAndTotals() {
        let bag = BagStore()
        let blend = MockShopService.products[1]
        bag.add(blend)
        bag.add(blend, quantity: 2)
        bag.add(MockShopService.products[2])
        #expect(bag.lines.count == 2)
        #expect(bag.itemCount == 4)
        #expect(bag.subtotal.amount == Decimal(string: "33.99"))
        #expect(bag.amountToFreeDelivery == Decimal(string: "16.01"))
    }

    @Test func optionsAreSeparateLines() {
        let bag = BagStore()
        let atelier = MockShopService.products[0]
        bag.add(atelier, option: atelier.options[0].values[0])
        bag.add(atelier, option: atelier.options[0].values[1])
        #expect(bag.lines.count == 2)
        #expect(bag.amountToFreeDelivery == 0)
    }

    @Test func zeroQuantityRemoves() {
        let bag = BagStore()
        bag.add(MockShopService.products[1])
        bag.setQuantity(0, for: bag.lines[0].id)
        #expect(bag.isEmpty)
    }
}

@MainActor
struct ShopViewModelTests {
    private func makeModel(pageSize: Int = 12) async -> ShopViewModel {
        let model = ShopViewModel(service: MockShopService(latency: .zero), bag: BagStore(), pageSize: pageSize)
        await model.load()
        return model
    }

    @Test func loadsCatalogCategoriesAndFeatured() async {
        let model = await makeModel()
        #expect(model.state == .loaded)
        #expect(model.products.count == MockShopService.products.count)
        #expect(model.categories.map(\.name) == ["Machines", "Tea"])
        #expect(model.featured?.sku == ShopViewModel.featuredSKU)
    }

    @Test func categoryAndSortReload() async throws {
        let model = await makeModel()
        model.sort = .priceLowHigh
        try await Task.sleep(for: .milliseconds(50))
        #expect(model.products.first?.sku == "POD341")
        model.category = model.categories.first { $0.name == "Machines" }
        try await Task.sleep(for: .milliseconds(50))
        #expect(model.products.map(\.sku) == ["CSM6001"])
        #expect(model.isFiltering)
    }

    @Test func searchIsDebounced() async throws {
        let model = await makeModel()
        model.searchText = "m"
        model.searchText = "mug"
        try await Task.sleep(for: .milliseconds(500))
        #expect(model.products.map(\.sku) == ["ACC563"])
        #expect(model.resultsTitle == "1 results for “mug”")
    }

    @Test func pagesLoadOnScroll() async {
        let model = await makeModel(pageSize: 2)
        #expect(model.products.count == 2)
        await model.loadMoreIfNeeded(after: model.products[1])
        #expect(model.products.count == 4)
    }
}

/// Hits the real Fréscopa Commerce endpoint. Run with LIVE_COMMERCE=1 in the scheme's environment.
struct LiveCommerceTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["LIVE_COMMERCE"] != nil))
    func liveCatalogResponds() async throws {
        let service = CommerceShopService()
        let page = try await service.search(ShopQuery(pageSize: 5))
        #expect(page.totalCount > 0)
        #expect(!(try await service.categories()).isEmpty)
    }
}
