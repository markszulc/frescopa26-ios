import Foundation
import Observation

/// The customer's bag. Kept on-device for now; checkout will hand these lines to the
/// Commerce cart API (`createGuestCart` / `addProductsToCart`) once that's wired up.
@MainActor
@Observable
final class BagStore {
    private(set) var lines: [BagLine] = []
    /// Bumped on every add so views can trigger feedback.
    private(set) var addedCount = 0
    private(set) var lastAdded: BagLine?

    var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    var isEmpty: Bool { lines.isEmpty }

    var subtotal: Money {
        let currency = lines.first?.product.price.currency ?? "USD"
        return Money(amount: lines.reduce(Decimal(0)) { $0 + $1.lineTotal.amount }, currency: currency)
    }

    /// Free delivery threshold, matching "Free delivery" messaging on frescopacoffee.com machines.
    static let freeDeliveryThreshold: Decimal = 50

    var amountToFreeDelivery: Decimal { max(Self.freeDeliveryThreshold - subtotal.amount, 0) }

    func add(_ product: ShopProduct, option: ProductOptionValue? = nil, quantity: Int = 1) {
        guard quantity > 0 else { return }
        let line = BagLine(product: product, option: option, quantity: quantity)
        if let index = lines.firstIndex(where: { $0.id == line.id }) {
            lines[index].quantity = min(lines[index].quantity + quantity, 99)
            lastAdded = lines[index]
        } else {
            lines.append(line)
            lastAdded = line
        }
        addedCount += 1
    }

    func setQuantity(_ quantity: Int, for lineID: BagLine.ID) {
        guard let index = lines.firstIndex(where: { $0.id == lineID }) else { return }
        if quantity <= 0 { lines.remove(at: index) } else { lines[index].quantity = min(quantity, 99) }
    }

    func remove(_ lineID: BagLine.ID) {
        lines.removeAll { $0.id == lineID }
    }

    func clear() { lines = [] }
}
