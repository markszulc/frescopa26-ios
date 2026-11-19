import Foundation

struct ShopCategory: Identifiable, Hashable, Sendable {
    var id: String { path }
    var name: String
    /// Commerce category path, e.g. "frescopa/machines". Used as the `categoryPath` filter.
    var path: String
}

enum ShopSort: String, CaseIterable, Identifiable, Hashable, Sendable {
    case featured, priceLowHigh, priceHighLow, name

    var id: String { rawValue }
    var title: String {
        switch self {
        case .featured: "Featured"
        case .priceLowHigh: "Price: low to high"
        case .priceHighLow: "Price: high to low"
        case .name: "Name"
        }
    }
    /// Commerce `ProductSearchSortInput` attribute + direction.
    var attribute: String {
        switch self {
        case .featured: "position"
        case .priceLowHigh, .priceHighLow: "price"
        case .name: "name"
        }
    }
    var direction: String {
        switch self {
        case .featured, .priceHighLow: "DESC"
        case .priceLowHigh, .name: "ASC"
        }
    }
}

struct ShopQuery: Equatable, Sendable {
    var phrase: String = ""
    var categoryPath: String?
    var sort: ShopSort = .featured
    var page: Int = 1
    var pageSize: Int = 12
}

struct Money: Equatable, Hashable, Sendable {
    var amount: Decimal
    var currency: String

    var formatted: String {
        let hasCents = amount != amount.rounded(scale: 0)
        return amount.formatted(.currency(code: currency).presentation(.narrow)
            .precision(.fractionLength(hasCents ? 2 : 0)))
    }
}

extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var value = self, result = Decimal()
        NSDecimalRound(&result, &value, scale, .plain)
        return result
    }
}

/// A selectable product option value, e.g. the Atelier's "Cream" finish.
struct ProductOptionValue: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var inStock: Bool
}

struct ProductOption: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var values: [ProductOptionValue]
}

/// A product as listed in the catalog.
struct ShopProduct: Identifiable, Hashable, Sendable {
    var id: String { sku }
    var sku: String
    var name: String
    var summary: String
    var price: Money
    /// Highest price for configurable products with a range.
    var maxPrice: Money?
    var inStock: Bool
    var imageURL: URL?
    var options: [ProductOption]
    var urlKey: String?

    var priceLabel: String {
        if let maxPrice, maxPrice.amount > price.amount { return "From \(price.formatted)" }
        return price.formatted
    }

    /// Resized rendition from the AEM asset delivery URL.
    func imageURL(width: Int) -> URL? {
        guard let imageURL else { return nil }
        var components = URLComponents(url: imageURL.appendingPathComponent("as/\(sku).jpg"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "quality", value: "80"), URLQueryItem(name: "width", value: "\(width)")]
        return components?.url
    }

    /// Rough product family, for placeholder artwork and icons.
    var family: Family {
        let lower = name.lowercased()
        if sku.hasPrefix("CSM") { return .machine }
        if sku.hasPrefix("TEA") { return .tea }
        if sku.hasPrefix("ACC") || sku.hasPrefix("ITT") { return .accessory }
        if lower.contains("pod") || sku.hasPrefix("POD") { return .pod }
        return .coffee
    }

    enum Family: Sendable { case machine, coffee, pod, tea, accessory }
}

struct ProductDetail: Equatable, Sendable {
    var product: ShopProduct
    var description: String
    var facts: [(label: String, value: String)]

    static func == (lhs: ProductDetail, rhs: ProductDetail) -> Bool {
        lhs.product == rhs.product && lhs.description == rhs.description
            && lhs.facts.map(\.label) == rhs.facts.map(\.label) && lhs.facts.map(\.value) == rhs.facts.map(\.value)
    }
}

struct ProductPage: Equatable, Sendable {
    var products: [ShopProduct]
    var totalCount: Int
    var currentPage: Int
    var totalPages: Int

    var hasMore: Bool { currentPage < totalPages }
}

/// One line in the bag.
struct BagLine: Identifiable, Hashable, Sendable {
    var id: String { option.map { "\(product.sku)#\($0.id)" } ?? product.sku }
    var product: ShopProduct
    var option: ProductOptionValue?
    var quantity: Int

    var lineTotal: Money { Money(amount: product.price.amount * Decimal(quantity), currency: product.price.currency) }
}

enum HTMLText {
    /// Strips tags and decodes common entities from Commerce rich-text fields.
    static func plain(_ html: String) -> String {
        var text = html
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "</p>\\s*<p[^>]*>", with: "\n\n", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let entities = ["&amp;": "&", "&nbsp;": " ", "&quot;": "\"", "&#39;": "'", "&apos;": "'",
                        "&lt;": "<", "&gt;": ">", "&ndash;": "–", "&mdash;": "—", "&rsquo;": "’", "&eacute;": "é"]
        for (entity, char) in entities { text = text.replacingOccurrences(of: entity, with: char) }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
