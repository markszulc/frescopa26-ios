import Foundation
import CoreLocation

/// What a café location offers. Every café pours the full range; showrooms and
/// workshop tables vary by location.
enum CafeAmenity: String, CaseIterable, Identifiable, Hashable, Sendable {
    case cafe, showroom, workshops

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cafe: "Café"
        case .showroom: "Showroom"
        case .workshops: "Workshops"
        }
    }

    var systemImage: String {
        switch self {
        case .cafe: "cup.and.saucer"
        case .showroom: "cube"
        case .workshops: "person.3"
        }
    }

    var blurb: String {
        switch self {
        case .cafe: "The taste bar pours the full coffee, tea and cold-press range."
        case .showroom: "The Atelier line, set up and running. Pull your own shot."
        case .workshops: "A long table for classes, labs and cuppings most evenings."
        }
    }
}

enum CafeRegion: String, CaseIterable, Identifiable, Hashable, Sendable {
    case east, midwest, south, west, international

    var id: String { rawValue }

    var title: String {
        switch self {
        case .east: "East"
        case .midwest: "Midwest"
        case .south: "South"
        case .west: "West"
        case .international: "International"
        }
    }
}

/// Daily opening hours in the café's local time (all locations open seven days).
struct OpeningHours: Equatable, Hashable, Sendable {
    /// Minutes after local midnight.
    var opens: Int
    var closes: Int

    init(opens: Int, closes: Int) {
        self.opens = opens
        self.closes = closes
    }

    /// Convenience: `OpeningHours(7, 20)` or `OpeningHours(6.5, 19)`.
    init(_ opens: Double, _ closes: Double) {
        self.opens = Int(opens * 60)
        self.closes = Int(closes * 60)
    }

    /// "7am–8pm"
    var rangeLabel: String { "\(Self.clock(opens))–\(Self.clock(closes))" }

    static func clock(_ minutes: Int) -> String {
        let hour24 = minutes / 60, minute = minutes % 60
        let suffix = hour24 >= 12 ? "pm" : "am"
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        return minute == 0 ? "\(hour12)\(suffix)" : "\(hour12):\(String(format: "%02d", minute))\(suffix)"
    }
}

struct Cafe: Identifiable, Equatable, Hashable, Sendable {
    var id: String
    var name: String
    var neighbourhood: String
    var city: String
    /// State or province code, e.g. "NY", "NSW".
    var region: String
    var street: String
    var country: String = "USA"
    var cafeRegion: CafeRegion
    var amenities: Set<CafeAmenity>
    var hours: OpeningHours
    var timeZoneID: String
    var latitude: Double
    var longitude: Double
    var isFlagship = false
    var summary: String?

    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var location: CLLocation { CLLocation(latitude: latitude, longitude: longitude) }
    var cityLine: String { "\(city), \(region)" }
    var fullAddress: String {
        country == "USA" ? "\(street), \(city), \(region)" : "\(street), \(city), \(region), \(country)"
    }
    var hasShowroom: Bool { amenities.contains(.showroom) }
    var hasWorkshops: Bool { amenities.contains(.workshops) }

    /// Amenities in display order.
    var sortedAmenities: [CafeAmenity] { CafeAmenity.allCases.filter(amenities.contains) }

    /// Whether the café is open at `date`, evaluated in the café's own time zone.
    func isOpen(at date: Date) -> Bool {
        let minutes = localMinutes(at: date)
        return minutes >= hours.opens && minutes < hours.closes
    }

    /// "Open · until 8pm" / "Closed · opens 7am"
    func openStatus(at date: Date) -> String {
        isOpen(at: date)
            ? "Open · until \(OpeningHours.clock(hours.closes))"
            : "Closed · opens \(OpeningHours.clock(hours.opens))"
    }

    private func localMinutes(at date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneID) ?? .current
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }
}

/// A class, lab or cupping at the long table.
struct CafeEvent: Identifiable, Equatable, Hashable, Sendable {
    var id: String
    /// Calendar weekday (1 = Sunday … 7 = Saturday).
    var weekday: Int
    var title: String
    var detail: String
    var startMinutes: Int
    var endMinutes: Int
    /// `nil` means free with a drink.
    var price: Decimal?
    var requiresBooking: Bool = true

    var timeLabel: String {
        "\(OpeningHours.clock(startMinutes))–\(OpeningHours.clock(endMinutes))"
    }

    var weekdayName: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_GB")
        return calendar.weekdaySymbols[(weekday - 1) % 7]
    }
}

/// One of the "Reasons to make the trip".
struct VisitReason: Identifiable, Equatable, Sendable {
    var id: String { title }
    var title: String
    var detail: String
    var systemImage: String
}

/// One of the three rooms in "The experience".
struct CafeRoom: Identifiable, Equatable, Sendable {
    var id: Int { number }
    var number: Int
    var name: String
    var headline: String
    var detail: String
    var linkTitle: String
}

struct CafeNetworkStats: Equatable, Sendable {
    var cafes: String
    var cities: String
    var states: String
    var showrooms: String
}

struct CafeDirectory: Equatable, Sendable {
    var cafes: [Cafe]
    var events: [CafeEvent]
    var stats: CafeNetworkStats

    var flagship: Cafe? { cafes.first(where: \.isFlagship) }
    var showrooms: [Cafe] { cafes.filter(\.hasShowroom) }
}

// MARK: - Atelier tour booking

enum TourInterest: String, CaseIterable, Identifiable, Hashable, Sendable {
    case atelierLine, espressoMilk, coldBrewTea, subscriptions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .atelierLine: "The Atelier line"
        case .espressoMilk: "Espresso & milk"
        case .coldBrewTea: "Cold brew & tea"
        case .subscriptions: "Bean subscriptions"
        }
    }
}

enum TourGuests: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case one = 1, two, three, four, fivePlus

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .one: "Just me"
        case .fivePlus: "5+"
        default: "\(rawValue)"
        }
    }
}

struct TourRequest: Equatable, Sendable {
    /// Start times on offer for each tour day, in minutes after midnight.
    static let slots: [Int] = [540, 630, 720, 810, 900, 990]

    var cafeID: String
    var date: Date
    var slot: Int?
    var guests: TourGuests = .one
    var name = ""
    var email = ""
    var phone = ""
    var interests: Set<TourInterest> = []

    var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return trimmed.wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]{2,}/) != nil
    }

    var isComplete: Bool {
        slot != nil && !name.trimmingCharacters(in: .whitespaces).isEmpty && isEmailValid
    }
}

struct TourConfirmation: Equatable, Sendable {
    var reference: String
    var cafeName: String
    var date: Date
    var slot: Int
    var email: String
}
