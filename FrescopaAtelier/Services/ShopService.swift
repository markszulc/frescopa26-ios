import Foundation

/// Catalog boundary for the Shop tab.
protocol ShopService: Sendable {
    func categories() async throws -> [ShopCategory]
    func search(_ query: ShopQuery) async throws -> ProductPage
    func product(sku: String) async throws -> ProductDetail?
}

// MARK: - Adobe Commerce (Catalog Service) implementation

/// Reads the live Fréscopa catalog from the same Adobe Commerce GraphQL endpoint
/// and store headers the frescopacoffee.com storefront uses (see its public /config.json).
struct CommerceShopService: ShopService {
    static let frescopa = GraphQLClient.Configuration(
        endpoint: URL(string: "https://na1.api.commerce.adobe.com/L54FdPU9mRQh5Ng7BBuvT4/graphql")!,
        headers: [
            "Store": "default",
            "Magento-Store-Code": "main_website_store",
            "Magento-Store-View-Code": "default",
            "Magento-Website-Code": "base",
        ]
    )

    /// Root category for the storefront; everything sellable lives under it.
    static let rootCategoryPath = "frescopa"

    var client = GraphQLClient(configuration: frescopa)

    func categories() async throws -> [ShopCategory] {
        let response = try await client.execute(Queries.categories, variables: NoVariables(), as: CategoriesResponse.self)
        // Top-level shop categories: direct children of the root ("frescopa/machines", "frescopa/tea"…).
        return response.categories
            .compactMap { dto -> ShopCategory? in
                guard let path = dto.urlPath, path.hasPrefix(Self.rootCategoryPath + "/") else { return nil }
                let depth = path.split(separator: "/").count
                return depth == 2 ? ShopCategory(name: dto.name, path: path) : nil
            }
            .sorted { $0.name < $1.name }
    }

    func search(_ query: ShopQuery) async throws -> ProductPage {
        var filters: [SearchClause] = [
            SearchClause(attribute: "categoryPath", eq: query.categoryPath ?? Self.rootCategoryPath, in: nil),
            SearchClause(attribute: "visibility", eq: nil, in: ["Search", "Catalog, Search"]),
        ]
        if query.categoryPath == nil && !query.phrase.isEmpty {
            // A phrase search spans the whole catalog root.
            filters[0] = SearchClause(attribute: "categoryPath", eq: Self.rootCategoryPath, in: nil)
        }
        let variables = SearchVariables(
            phrase: query.phrase,
            pageSize: query.pageSize,
            currentPage: query.page,
            filter: filters,
            sort: query.phrase.isEmpty ? [SortInput(attribute: query.sort.attribute, direction: query.sort.direction)]
                : (query.sort == .featured ? [SortInput(attribute: "relevance", direction: "DESC")]
                   : [SortInput(attribute: query.sort.attribute, direction: query.sort.direction)])
        )
        let response = try await client.execute(Queries.productSearch, variables: variables, as: SearchResponse.self)
        let result = response.productSearch
        return ProductPage(
            products: result.items.compactMap { $0.productView?.model },
            totalCount: result.totalCount,
            currentPage: result.pageInfo.currentPage,
            totalPages: max(result.pageInfo.totalPages, 1)
        )
    }

    func product(sku: String) async throws -> ProductDetail? {
        let response = try await client.execute(Queries.productDetail, variables: SKUVariables(skus: [sku]), as: ProductsResponse.self)
        guard let dto = response.products.first else { return nil }
        return ProductDetail(product: dto.model,
                             description: HTMLText.plain(dto.description ?? dto.shortDescription ?? ""),
                             facts: dto.facts)
    }

    // MARK: Queries (shaped after the storefront's PLP/PDP drop-in queries)

    enum Queries {
        static let productFields = """
        __typename sku name inStock urlKey shortDescription
        images(roles: []) { url roles }
        ... on SimpleProductView { price { final { amount { value currency } } } }
        ... on ComplexProductView {
          priceRange { minimum { final { amount { value currency } } } maximum { final { amount { value currency } } } }
          options { id title values { id title inStock } }
        }
        """

        static let categories = "query PLP_CATEGORIES { categories { name urlKey urlPath } }"

        static let productSearch = """
        query productSearch($phrase: String!, $pageSize: Int, $currentPage: Int = 1,
                            $filter: [SearchClauseInput!], $sort: [ProductSearchSortInput!]) {
          productSearch(phrase: $phrase, page_size: $pageSize, current_page: $currentPage, filter: $filter, sort: $sort) {
            total_count
            page_info { current_page page_size total_pages }
            items { productView { \(productFields) } }
          }
        }
        """

        static let productDetail = """
        query PDP($skus: [String]) {
          products(skus: $skus) {
            \(productFields)
            description
            attributes(roles: []) { name label value }
          }
        }
        """
    }
}

// MARK: - Wire types

private struct SearchClause: Encodable, Sendable {
    let attribute: String
    let eq: String?
    let `in`: [String]?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(attribute, forKey: .attribute)
        try container.encodeIfPresent(eq, forKey: .eq)
        try container.encodeIfPresent(`in`, forKey: .in)
    }
    enum CodingKeys: String, CodingKey { case attribute, eq, `in` }
}

private struct SortInput: Encodable, Sendable { let attribute: String; let direction: String }

private struct SearchVariables: Encodable, Sendable {
    let phrase: String
    let pageSize: Int
    let currentPage: Int
    let filter: [SearchClause]
    let sort: [SortInput]
}

private struct SKUVariables: Encodable, Sendable { let skus: [String] }

struct CategoriesResponse: Decodable, Sendable {
    struct Category: Decodable, Sendable { let name: String; let urlPath: String? }
    let categories: [Category]
}

struct SearchResponse: Decodable, Sendable {
    struct Result: Decodable, Sendable {
        let totalCount: Int
        let pageInfo: PageInfo
        let items: [Item]
        enum CodingKeys: String, CodingKey { case totalCount = "total_count", pageInfo = "page_info", items }
    }
    struct PageInfo: Decodable, Sendable {
        let currentPage: Int
        let totalPages: Int
        enum CodingKeys: String, CodingKey { case currentPage = "current_page", totalPages = "total_pages" }
    }
    struct Item: Decodable, Sendable { let productView: ProductViewDTO? }
    let productSearch: Result
}

struct ProductsResponse: Decodable, Sendable {
    let products: [ProductViewDTO]
}

/// `ProductView` union (SimpleProductView | ComplexProductView), flattened.
struct ProductViewDTO: Decodable, Sendable {
    struct Amount: Decodable, Sendable {
        let value: Decimal
        let currency: String

        enum CodingKeys: String, CodingKey { case value, currency }

        /// JSON numbers decode through Double; re-parse the shortest decimal form so
        /// 3.99 stays exactly 3.99 rather than 3.99000000000000051…
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let raw = try container.decode(Double.self, forKey: .value)
            value = Decimal(string: String(raw), locale: Locale(identifier: "en_US_POSIX")) ?? Decimal(raw)
            currency = try container.decode(String.self, forKey: .currency)
        }
    }
    struct Final: Decodable, Sendable { let final: AmountBox }
    struct AmountBox: Decodable, Sendable { let amount: Amount }
    struct PriceRange: Decodable, Sendable { let minimum: Final; let maximum: Final? }
    struct Image: Decodable, Sendable { let url: String; let roles: [String]? }
    struct Option: Decodable, Sendable {
        struct Value: Decodable, Sendable { let id: String; let title: String; let inStock: Bool? }
        let id: String
        let title: String
        let values: [Value]
    }
    struct Attribute: Decodable, Sendable {
        let name: String
        let label: String?
        let value: AttributeValue?
    }

    let typename: String
    let sku: String
    let name: String
    let inStock: Bool?
    let urlKey: String?
    let shortDescription: String?
    let description: String?
    let images: [Image]?
    let price: Final?
    let priceRange: PriceRange?
    let options: [Option]?
    let attributes: [Attribute]?

    enum CodingKeys: String, CodingKey {
        case typename = "__typename", sku, name, inStock, urlKey, shortDescription, description, images, price,
             priceRange, options, attributes
    }

    var model: ShopProduct {
        let minimum = price?.final.amount ?? priceRange?.minimum.final.amount
        let maximum = priceRange?.maximum?.final.amount
        let image = images?.first { $0.roles?.contains("image") ?? false } ?? images?.first
        return ShopProduct(
            sku: sku,
            name: name,
            summary: HTMLText.plain(shortDescription ?? ""),
            price: Money(amount: minimum?.value ?? 0, currency: minimum?.currency ?? "USD"),
            maxPrice: maximum.map { Money(amount: $0.value, currency: $0.currency) },
            inStock: inStock ?? true,
            imageURL: image.flatMap { URL(string: $0.url.hasPrefix("//") ? "https:" + $0.url : $0.url) },
            options: (options ?? []).map { option in
                ProductOption(id: option.id, title: option.title,
                              values: option.values.map { ProductOptionValue(id: $0.id, title: $0.title, inStock: $0.inStock ?? true) })
            },
            urlKey: urlKey
        )
    }

    /// Customer-facing attributes only (skips Commerce's internal ac_* / cost / role fields).
    var facts: [(label: String, value: String)] {
        let shown: [String: String] = ["coffee_format": "Format", "finish": "Finish", "weight": "Weight"]
        return (attributes ?? []).compactMap { attribute in
            guard let label = shown[attribute.name], let value = attribute.value?.text, !value.isEmpty else { return nil }
            return (label, attribute.name == "weight" ? "\(value) kg" : value)
        }
    }
}

/// Attribute values arrive as strings, numbers, bools or JSON; keep a readable string.
struct AttributeValue: Decodable, Sendable {
    let text: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) { text = string }
        else if let number = try? container.decode(Double.self) { text = number.formatted() }
        else if let bool = try? container.decode(Bool.self) { text = bool ? "Yes" : "No" }
        else { text = nil }
    }
}

// MARK: - Mock (previews & tests)

struct MockShopService: ShopService {
    var latency: Duration = .milliseconds(200)

    static let products: [ShopProduct] = [
        ShopProduct(sku: "CSM6001", name: "The Atelier", summary: "The flagship bean-to-cup machine that learns your taste.",
                    price: Money(amount: 2199, currency: "USD"), maxPrice: nil, inStock: true, imageURL: nil,
                    options: [ProductOption(id: "finish", title: "Finish", values: [
                        .init(id: "cream", title: "Cream", inStock: true),
                        .init(id: "charcoal", title: "Charcoal", inStock: true),
                        .init(id: "terracotta", title: "Terracotta", inStock: false)])],
                    urlKey: "the-atelier"),
        ShopProduct(sku: "COF-MB", name: "Morning Blend", summary: "A smooth, full-bodied blend to ease you into the day.",
                    price: Money(amount: 10, currency: "USD"), maxPrice: nil, inStock: true, imageURL: nil, options: [], urlKey: nil),
        ShopProduct(sku: "POD341", name: "Midnight Oil - Dark Roast", summary: "Candied hazelnut and chocolate.",
                    price: Money(amount: Decimal(string: "3.99")!, currency: "USD"), maxPrice: nil, inStock: true, imageURL: nil, options: [], urlKey: nil),
        ShopProduct(sku: "TEA103", name: "Sunrise Meadow", summary: "A soothing blend of a blooming meadow.",
                    price: Money(amount: Decimal(string: "7.99")!, currency: "USD"), maxPrice: nil, inStock: true, imageURL: nil, options: [], urlKey: nil),
        ShopProduct(sku: "ACC563", name: "Espresso Mug", summary: "", price: Money(amount: Decimal(string: "4.99")!, currency: "USD"),
                    maxPrice: nil, inStock: true, imageURL: nil, options: [], urlKey: nil),
    ]

    func categories() async throws -> [ShopCategory] {
        try await Task.sleep(for: latency)
        return [ShopCategory(name: "Machines", path: "frescopa/machines"),
                ShopCategory(name: "Tea", path: "frescopa/tea")]
    }

    func search(_ query: ShopQuery) async throws -> ProductPage {
        try await Task.sleep(for: latency)
        var items = Self.products
        if query.categoryPath == "frescopa/machines" { items = items.filter { $0.family == .machine } }
        if query.categoryPath == "frescopa/tea" { items = items.filter { $0.family == .tea } }
        if !query.phrase.isEmpty { items = items.filter { $0.name.localizedCaseInsensitiveContains(query.phrase) } }
        switch query.sort {
        case .priceLowHigh: items.sort { $0.price.amount < $1.price.amount }
        case .priceHighLow: items.sort { $0.price.amount > $1.price.amount }
        case .name: items.sort { $0.name < $1.name }
        case .featured: break
        }
        let pages = max(Int((Double(items.count) / Double(query.pageSize)).rounded(.up)), 1)
        let slice = Array(items.dropFirst((query.page - 1) * query.pageSize).prefix(query.pageSize))
        return ProductPage(products: slice, totalCount: items.count, currentPage: query.page, totalPages: pages)
    }

    func product(sku: String) async throws -> ProductDetail? {
        try await Task.sleep(for: latency)
        guard let product = Self.products.first(where: { $0.sku == sku }) else { return nil }
        return ProductDetail(product: product, description: product.summary, facts: [("Format", "Ground")])
    }
}
