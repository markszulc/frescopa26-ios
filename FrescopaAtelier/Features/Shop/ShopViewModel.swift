import Foundation
import Observation

@MainActor
@Observable
final class ShopViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: LoadState = .idle
    private(set) var categories: [ShopCategory] = []
    private(set) var products: [ShopProduct] = []
    private(set) var totalCount = 0
    private(set) var featured: ShopProduct?
    private(set) var isLoadingMore = false
    private var page = ProductPage(products: [], totalCount: 0, currentPage: 0, totalPages: 1)

    var category: ShopCategory? { didSet { if oldValue != category { scheduleReload(debounce: false) } } }
    var sort: ShopSort = .featured { didSet { if oldValue != sort { scheduleReload(debounce: false) } } }
    var searchText = "" { didSet { if oldValue != searchText { scheduleReload(debounce: true) } } }

    let service: ShopService
    let bag: BagStore
    let pageSize: Int
    @ObservationIgnored private var reloadTask: Task<Void, Never>?

    /// SKU of the hero product shown above the grid.
    static let featuredSKU = "CSM6001"

    init(service: ShopService, bag: BagStore, pageSize: Int = 12) {
        self.service = service
        self.bag = bag
        self.pageSize = pageSize
    }

    var isFiltering: Bool { category != nil || !searchText.isEmpty }

    var resultsTitle: String {
        if !searchText.isEmpty { return "\(totalCount) results for “\(searchText)”" }
        return "\(totalCount) \(totalCount == 1 ? "product" : "products")"
    }

    // MARK: Loading

    /// First load: categories, the hero product and page one, in parallel.
    func load() async {
        guard state == .idle || isFailed else { return }
        state = .loading
        async let categoriesResult = try? service.categories()
        async let featuredResult = try? service.product(sku: Self.featuredSKU)
        await reload()
        categories = await categoriesResult ?? categories
        featured = await featuredResult?.product ?? featured
    }

    func refresh() async {
        await reload()
    }

    private var isFailed: Bool { if case .failed = state { true } else { false } }

    private func currentQuery(page: Int) -> ShopQuery {
        ShopQuery(phrase: searchText.trimmingCharacters(in: .whitespaces), categoryPath: category?.path,
                  sort: sort, page: page, pageSize: pageSize)
    }

    private func reload() async {
        do {
            let first = try await service.search(currentQuery(page: 1))
            try Task.checkCancellation()
            page = first
            products = first.products
            totalCount = first.totalCount
            state = .loaded
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            if products.isEmpty {
                state = .failed((error as? LocalizedError)?.errorDescription ?? "We couldn't reach the shop. Pull to try again.")
            }
        }
    }

    private func scheduleReload(debounce: Bool) {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            if debounce { try? await Task.sleep(for: .milliseconds(350)) }
            guard !Task.isCancelled else { return }
            await self?.reload()
        }
    }

    /// Infinite scroll: fetch the next page when the user nears the end.
    func loadMoreIfNeeded(after product: ShopProduct) async {
        guard page.hasMore, !isLoadingMore,
              let index = products.firstIndex(of: product), index >= products.count - 4 else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let next = try await service.search(currentQuery(page: page.currentPage + 1))
            page = next
            let known = Set(products.map(\.sku))
            products += next.products.filter { !known.contains($0.sku) }
        } catch {
            // Leave the list as-is; the next scroll retries.
        }
    }

    func clearFilters() {
        searchText = ""
        category = nil
    }
}

/// Drives the product detail screen.
@MainActor
@Observable
final class ProductDetailModel {
    enum LoadState: Equatable { case loading, loaded, failed }

    private(set) var detail: ProductDetail?
    private(set) var state: LoadState = .loading
    var selectedOption: ProductOptionValue?
    var quantity = 1

    let product: ShopProduct
    private let service: ShopService

    init(product: ShopProduct, service: ShopService) {
        self.product = product
        self.service = service
        selectedOption = product.options.first?.values.first { $0.inStock }
    }

    var displayProduct: ShopProduct { detail?.product ?? product }
    var option: ProductOption? { displayProduct.options.first }
    var canAdd: Bool { displayProduct.inStock && (option == nil || selectedOption != nil) }

    func load() async {
        do {
            detail = try await service.product(sku: product.sku)
            if selectedOption == nil { selectedOption = displayProduct.options.first?.values.first { $0.inStock } }
            state = .loaded
        } catch {
            state = detail == nil ? .failed : .loaded
        }
    }
}
