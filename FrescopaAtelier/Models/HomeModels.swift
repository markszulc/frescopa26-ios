import Foundation

struct UserProfile: Equatable, Sendable {
    var firstName: String
    var unreadNotifications: Int
}

/// The connected Fréscopa machine.
struct Machine: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case ready, brewing, cupReady, offline

        var label: String {
            switch self {
            case .ready: "Ready"
            case .brewing: "Brewing"
            case .cupReady: "Cup ready"
            case .offline: "Offline"
            }
        }
    }

    struct Levels: Equatable, Sendable {
        /// All values are 0...1.
        var water: Double
        var beans: Double
        var filter: Double
    }

    var name: String
    var room: String
    var status: Status
    var levels: Levels
}

/// The AI-tuned "usual" for today.
struct BrewRecommendation: Equatable, Sendable {
    var eyebrow: String
    var title: String
    var rationale: String
    /// The exact cup to brew when the customer taps "Brew now".
    var order: BrewOrder
}

struct SupplyStatus: Equatable, Sendable {
    var blendName: String
    var cupsRemaining: Int
    var nextDelivery: Date
    /// Set once the customer has asked for the next shipment to be sent early.
    var expeditedDelivery: Date?

    var isExpedited: Bool { expeditedDelivery != nil }
}

struct Offer: Identifiable, Equatable, Sendable {
    enum Artwork: Equatable, Sendable {
        /// Asset-catalogue image with a focal point (0...1) for cropping.
        case image(name: String, focusY: Double)
        /// Brand gradient fallback when no photography is available.
        case gradient
    }

    var id: String
    var badge: String
    var title: String
    var detail: String
    var callToAction: String
    var artwork: Artwork
    var deepLink: URL?
}

struct ProductPick: Identifiable, Equatable, Sendable {
    enum Kind: Sendable { case coffee, tea, juice }

    var id: String
    var matchLabel: String
    var title: String
    var price: Decimal
    var currencyCode: String
    /// Asset name; when `nil` a branded placeholder is drawn.
    var imageName: String?
    var imageDescription: String
    var kind: Kind
}

struct TasteProfile: Equatable, Sendable {
    struct Attribute: Identifiable, Equatable, Sendable {
        var id: String { label }
        var label: String
        /// 0...1
        var value: Double
    }

    var headline: String
    var attributes: [Attribute]
}

struct QuickAction: Identifiable, Equatable, Sendable {
    enum Destination: Sendable { case brewMenu, reorder, care, cafes }

    var id: Destination { destination }
    var title: String
    var icon: BrandIcon
    var destination: Destination
}

/// Everything the home screen needs in one payload.
struct HomeContent: Equatable, Sendable {
    var user: UserProfile
    var machine: Machine
    var recommendation: BrewRecommendation
    var supply: SupplyStatus
    var offers: [Offer]
    var picks: [ProductPick]
    var taste: TasteProfile
}
