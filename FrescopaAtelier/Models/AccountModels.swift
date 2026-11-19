import Foundation

struct Membership: Equatable, Sendable {
    var tier: String
    var memberSince: Date
    /// Reward "beans" earned from cups, orders and café visits.
    var points: Int
    var nextRewardAt: Int
    var nextRewardTitle: String

    var progress: Double { min(Double(points) / Double(max(nextRewardAt, 1)), 1) }
    var pointsToGo: Int { max(nextRewardAt - points, 0) }
}

struct AccountProfile: Equatable, Sendable {
    var firstName: String
    var lastName: String
    var email: String
    var city: String

    var initials: String {
        [firstName.first, lastName.first].compactMap { $0 }.map(String.init).joined()
    }
    var fullName: String { lastName.isEmpty ? firstName : "\(firstName) \(lastName)" }
}

enum DeliveryCadence: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case weekly = 1, fortnightly = 2, threeWeeks = 3, monthly = 4

    var id: Int { rawValue }
    var weeks: Int { rawValue }
    var title: String {
        switch self {
        case .weekly: "Every week"
        case .fortnightly: "Every 2 weeks"
        case .threeWeeks: "Every 3 weeks"
        case .monthly: "Every 4 weeks"
        }
    }
}

struct Subscription: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case active
        case paused(until: Date)
    }

    var productName: String
    var bagSizeGrams: Int
    var bags: Int
    var cadence: DeliveryCadence
    var pricePerDelivery: Decimal
    var nextDelivery: Date
    var status: Status

    var isPaused: Bool { if case .paused = status { true } else { false } }
    var quantityLabel: String { "\(bags) × \(bagSizeGrams) g" }
}

/// A recurring maintenance task for the machine.
struct CareTask: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var detail: String
    /// 0...1 remaining life before the task is due.
    var remaining: Double
    var dueIn: String
    var systemImage: String

    var isDueSoon: Bool { remaining < 0.2 }
}

struct OwnedMachine: Equatable, Sendable {
    var name: String
    var model: String
    var room: String
    var serial: String
    var firmware: String
    var cupsBrewed: Int
    var care: [CareTask]
}

/// One week of the flavour DNA, for the history chart.
struct TasteWeek: Identifiable, Equatable, Sendable {
    var id: Date { weekStart }
    var weekStart: Date
    var body: Double
    var sweetness: Double
    var acidity: Double
}

struct OrderSummary: Identifiable, Equatable, Sendable {
    enum Status: String, Sendable {
        case processing = "Processing"
        case shipped = "On its way"
        case delivered = "Delivered"
    }

    var id: String
    var title: String
    var itemCount: Int
    var total: Decimal
    var date: Date
    var status: Status
}

struct NotificationPreferences: Equatable, Sendable {
    var brewReminders = true
    var deliveryUpdates = true
    var cafeEvents = false
    var offers = true
}

struct AccountOverview: Equatable, Sendable {
    var profile: AccountProfile
    var membership: Membership
    var subscription: Subscription
    var machine: OwnedMachine
    var tasteHistory: [TasteWeek]
    var orders: [OrderSummary]
    var notifications: NotificationPreferences
}
