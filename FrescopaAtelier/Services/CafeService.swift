import Foundation

/// Backend boundary for the Cafés tab.
protocol CafeService: Sendable {
    func loadDirectory() async throws -> CafeDirectory
    /// Saves a seat at a long-table event. Returns the event ID on success.
    func saveSeat(for eventID: CafeEvent.ID) async throws
    func cancelSeat(for eventID: CafeEvent.ID) async throws
    func requestTour(_ request: TourRequest) async throws -> TourConfirmation
}

enum CafeServiceError: LocalizedError {
    case unknownCafe
    case incompleteRequest

    var errorDescription: String? {
        switch self {
        case .unknownCafe: "That café isn't taking tour bookings right now."
        case .incompleteRequest: "Please choose a time and add your name and email."
        }
    }
}

struct MockCafeService: CafeService {
    var latency: Duration = .milliseconds(300)

    func loadDirectory() async throws -> CafeDirectory {
        try await Task.sleep(for: latency)
        return Self.directory
    }

    func saveSeat(for eventID: CafeEvent.ID) async throws {
        try await Task.sleep(for: .milliseconds(400))
    }

    func cancelSeat(for eventID: CafeEvent.ID) async throws {
        try await Task.sleep(for: .milliseconds(250))
    }

    func requestTour(_ request: TourRequest) async throws -> TourConfirmation {
        try await Task.sleep(for: .milliseconds(700))
        guard let cafe = Self.directory.cafes.first(where: { $0.id == request.cafeID }), cafe.hasShowroom else {
            throw CafeServiceError.unknownCafe
        }
        guard request.isComplete, let slot = request.slot else { throw CafeServiceError.incompleteRequest }
        return TourConfirmation(
            reference: "FT-" + String(UUID().uuidString.prefix(6)),
            cafeName: cafe.name,
            date: request.date,
            slot: slot,
            email: request.email
        )
    }

    // MARK: - Content (mirrors frescopacoffee.com/cafe)

    static let reasons: [VisitReason] = [
        .init(title: "Taste before you commit",
              detail: "Flight through the coffee, tea and cold-press range at the bar. Find the cup you'll want at home.",
              systemImage: "cup.and.saucer"),
        .init(title: "Meet the machines",
              detail: "Pull a shot on the Atelier line yourself. Feel the difference before it lands on your counter.",
              systemImage: "cube"),
        .init(title: "Learn from the team",
              detail: "Brewing classes, latte-art labs and cuppings led by people who do it every day.",
              systemImage: "person.3"),
        .init(title: "Somewhere to linger",
              detail: "A warm room to meet, work, or read the morning away. Come for the coffee, stay for the quiet.",
              systemImage: "book"),
    ]

    static let rooms: [CafeRoom] = [
        .init(number: 1, name: "The Taste Bar", headline: "Every drink we make, poured to order.",
              detail: "Work through the range — espresso and slow-pour coffee, loose-leaf tea, and cold-pressed juice. Our team builds a tasting flight around what you like.",
              linkTitle: "Browse the coffee range"),
        .init(number: 2, name: "The Showroom", headline: "Get your hands on the whole line.",
              detail: "The full Atelier range, set up and running. Pull your own shot, watch the machine learn a profile, and ask the questions a spec sheet can't answer.",
              linkTitle: "Explore the machines"),
        .init(number: 3, name: "The Table", headline: "Learn something, meet someone.",
              detail: "Most evenings the long table hosts something — a brewing class, a latte-art lab, a cupping, or a slow community morning. Small, hands-on, mostly free with a drink.",
              linkTitle: "See what's on"),
    ]

    static let directory = CafeDirectory(
        cafes: cafes,
        events: [
            CafeEvent(id: "origins-cupping", weekday: 3, title: "Origins cupping",
                      detail: "Taste three single-origin lots side by side and learn to name what you taste.",
                      startMinutes: 1110, endMinutes: 1170, price: nil),
            CafeEvent(id: "latte-art-lab", weekday: 4, title: "Latte-art lab",
                      detail: "Hands-on milk steaming and pour practice on the Atelier line. Beginners welcome.",
                      startMinutes: 1080, endMinutes: 1170, price: 15),
            CafeEvent(id: "home-brewing-101", weekday: 5, title: "Home brewing 101",
                      detail: "Dial in grind, dose and time for a filter cup you can repeat at home.",
                      startMinutes: 1110, endMinutes: 1200, price: nil),
            CafeEvent(id: "slow-morning-cupping", weekday: 7, title: "Slow morning cupping",
                      detail: "A relaxed community tasting over pastries. Drop in, no booking needed.",
                      startMinutes: 540, endMinutes: 660, price: nil, requiresBooking: false),
        ],
        stats: CafeNetworkStats(cafes: "1,200+", cities: "190", states: "48", showrooms: "12")
    )

    private static let ny = "America/New_York", chi = "America/Chicago", den = "America/Denver",
                       phx = "America/Phoenix", la = "America/Los_Angeles"

    static let cafes: [Cafe] = [
        Cafe(id: "soho", name: "Fréscopa SoHo", neighbourhood: "SoHo", city: "New York", region: "NY",
             street: "112 Greene Street", cafeRegion: .east, amenities: [.cafe, .showroom, .workshops],
             hours: .init(7, 20), timeZoneID: ny, latitude: 40.7247, longitude: -73.9989, isFlagship: true,
             summary: "Our largest room: a full taste bar, the complete showroom, and a dedicated workshop table upstairs. The best place to spend an unhurried afternoon in the Fréscopa world."),
        Cafe(id: "williamsburg", name: "Fréscopa Williamsburg", neighbourhood: "Williamsburg", city: "Brooklyn", region: "NY",
             street: "134 N 6th St", cafeRegion: .east, amenities: [.cafe, .showroom],
             hours: .init(7, 20), timeZoneID: ny, latitude: 40.7186, longitude: -73.9590),
        Cafe(id: "seaport", name: "Fréscopa Seaport", neighbourhood: "Seaport", city: "Boston", region: "MA",
             street: "48 Harbor Way", cafeRegion: .east, amenities: [.cafe, .showroom],
             hours: .init(7, 19), timeZoneID: ny, latitude: 42.3505, longitude: -71.0446),
        Cafe(id: "back-bay", name: "Fréscopa Back Bay", neighbourhood: "Back Bay", city: "Boston", region: "MA",
             street: "221 Newbury St", cafeRegion: .east, amenities: [.cafe],
             hours: .init(6.5, 19), timeZoneID: ny, latitude: 42.3497, longitude: -71.0810),
        Cafe(id: "rittenhouse", name: "Fréscopa Rittenhouse", neighbourhood: "Rittenhouse", city: "Philadelphia", region: "PA",
             street: "1820 Walnut St", cafeRegion: .east, amenities: [.cafe, .workshops],
             hours: .init(7, 19), timeZoneID: ny, latitude: 39.9500, longitude: -75.1717),
        Cafe(id: "georgetown", name: "Fréscopa Georgetown", neighbourhood: "Georgetown", city: "Washington", region: "DC",
             street: "3040 M St NW", cafeRegion: .east, amenities: [.cafe, .showroom],
             hours: .init(7, 19), timeZoneID: ny, latitude: 38.9050, longitude: -77.0605),
        Cafe(id: "ponce-city-market", name: "Fréscopa Ponce City Market", neighbourhood: "Ponce City Market", city: "Atlanta", region: "GA",
             street: "675 Ponce De Leon Ave NE", cafeRegion: .south, amenities: [.cafe, .showroom, .workshops],
             hours: .init(7, 20), timeZoneID: ny, latitude: 33.7726, longitude: -84.3656),
        Cafe(id: "west-loop", name: "Fréscopa West Loop", neighbourhood: "West Loop", city: "Chicago", region: "IL",
             street: "905 W Fulton Market", cafeRegion: .midwest, amenities: [.cafe, .showroom, .workshops],
             hours: .init(7, 19), timeZoneID: chi, latitude: 41.8868, longitude: -87.6497),
        Cafe(id: "wicker-park", name: "Fréscopa Wicker Park", neighbourhood: "Wicker Park", city: "Chicago", region: "IL",
             street: "1547 N Milwaukee Ave", cafeRegion: .midwest, amenities: [.cafe],
             hours: .init(6.5, 19), timeZoneID: chi, latitude: 41.9095, longitude: -87.6766),
        Cafe(id: "north-loop", name: "Fréscopa North Loop", neighbourhood: "North Loop", city: "Minneapolis", region: "MN",
             street: "215 N Washington Ave", cafeRegion: .midwest, amenities: [.cafe, .workshops],
             hours: .init(7, 18), timeZoneID: chi, latitude: 44.9830, longitude: -93.2706),
        Cafe(id: "crossroads", name: "Fréscopa Crossroads", neighbourhood: "Crossroads", city: "Kansas City", region: "MO",
             street: "1801 Grand Blvd", cafeRegion: .midwest, amenities: [.cafe],
             hours: .init(7, 18), timeZoneID: chi, latitude: 39.0918, longitude: -94.5806),
        Cafe(id: "rino", name: "Fréscopa RiNo", neighbourhood: "RiNo", city: "Denver", region: "CO",
             street: "2601 Larimer St", cafeRegion: .west, amenities: [.cafe, .showroom],
             hours: .init(7, 19), timeZoneID: den, latitude: 39.7590, longitude: -104.9857),
        Cafe(id: "south-congress", name: "Fréscopa South Congress", neighbourhood: "South Congress", city: "Austin", region: "TX",
             street: "1601 S Congress Ave", cafeRegion: .south, amenities: [.cafe, .workshops],
             hours: .init(7, 18), timeZoneID: chi, latitude: 30.2490, longitude: -97.7500),
        Cafe(id: "the-domain", name: "Fréscopa The Domain", neighbourhood: "The Domain", city: "Austin", region: "TX",
             street: "11700 Domain Blvd", cafeRegion: .south, amenities: [.cafe, .showroom],
             hours: .init(7, 20), timeZoneID: chi, latitude: 30.4021, longitude: -97.7253),
        Cafe(id: "deep-ellum", name: "Fréscopa Deep Ellum", neighbourhood: "Deep Ellum", city: "Dallas", region: "TX",
             street: "2822 Main St", cafeRegion: .south, amenities: [.cafe, .showroom],
             hours: .init(7, 19), timeZoneID: chi, latitude: 32.7845, longitude: -96.7838),
        Cafe(id: "the-heights", name: "Fréscopa The Heights", neighbourhood: "The Heights", city: "Houston", region: "TX",
             street: "714 Yale St", cafeRegion: .south, amenities: [.cafe],
             hours: .init(7, 19), timeZoneID: chi, latitude: 29.7838, longitude: -95.3985),
        Cafe(id: "wynwood", name: "Fréscopa Wynwood", neighbourhood: "Wynwood", city: "Miami", region: "FL",
             street: "2750 NW 3rd Ave", cafeRegion: .south, amenities: [.cafe, .showroom, .workshops],
             hours: .init(7, 21), timeZoneID: ny, latitude: 25.8016, longitude: -80.1990),
        Cafe(id: "warehouse-district", name: "Fréscopa Warehouse District", neighbourhood: "Warehouse District", city: "New Orleans", region: "LA",
             street: "640 Julia St", cafeRegion: .south, amenities: [.cafe, .workshops],
             hours: .init(7, 19), timeZoneID: chi, latitude: 29.9446, longitude: -90.0700),
        Cafe(id: "ferry-building", name: "Fréscopa Ferry Building", neighbourhood: "Ferry Building", city: "San Francisco", region: "CA",
             street: "1 Ferry Building", cafeRegion: .west, amenities: [.cafe, .showroom],
             hours: .init(7, 19), timeZoneID: la, latitude: 37.7955, longitude: -122.3937),
        Cafe(id: "hayes-valley", name: "Fréscopa Hayes Valley", neighbourhood: "Hayes Valley", city: "San Francisco", region: "CA",
             street: "556 Hayes St", cafeRegion: .west, amenities: [.cafe],
             hours: .init(6.5, 19), timeZoneID: la, latitude: 37.7766, longitude: -122.4260),
        Cafe(id: "capitol-hill", name: "Fréscopa Capitol Hill", neighbourhood: "Capitol Hill", city: "Seattle", region: "WA",
             street: "520 E Pine St", cafeRegion: .west, amenities: [.cafe, .workshops],
             hours: .init(6.5, 19), timeZoneID: la, latitude: 47.6153, longitude: -122.3260),
        Cafe(id: "ballard", name: "Fréscopa Ballard", neighbourhood: "Ballard", city: "Seattle", region: "WA",
             street: "5405 Ballard Ave NW", cafeRegion: .west, amenities: [.cafe, .showroom],
             hours: .init(7, 19), timeZoneID: la, latitude: 47.6680, longitude: -122.3840),
        Cafe(id: "pearl-district", name: "Fréscopa Pearl District", neighbourhood: "Pearl District", city: "Portland", region: "OR",
             street: "1130 NW Everett St", cafeRegion: .west, amenities: [.cafe, .workshops],
             hours: .init(7, 19), timeZoneID: la, latitude: 45.5251, longitude: -122.6829),
        Cafe(id: "arts-district", name: "Fréscopa Arts District", neighbourhood: "Arts District", city: "Los Angeles", region: "CA",
             street: "720 E 3rd St", cafeRegion: .west, amenities: [.cafe, .showroom, .workshops],
             hours: .init(7, 20), timeZoneID: la, latitude: 34.0459, longitude: -118.2380),
        Cafe(id: "silver-lake", name: "Fréscopa Silver Lake", neighbourhood: "Silver Lake", city: "Los Angeles", region: "CA",
             street: "2909 Sunset Blvd", cafeRegion: .west, amenities: [.cafe],
             hours: .init(6.5, 20), timeZoneID: la, latitude: 34.0876, longitude: -118.2780),
        Cafe(id: "little-italy", name: "Fréscopa Little Italy", neighbourhood: "Little Italy", city: "San Diego", region: "CA",
             street: "1660 India St", cafeRegion: .west, amenities: [.cafe, .showroom],
             hours: .init(7, 19), timeZoneID: la, latitude: 32.7230, longitude: -117.1690),
        Cafe(id: "roosevelt-row", name: "Fréscopa Roosevelt Row", neighbourhood: "Roosevelt Row", city: "Phoenix", region: "AZ",
             street: "814 N 2nd St", cafeRegion: .west, amenities: [.cafe],
             hours: .init(7, 19), timeZoneID: phx, latitude: 33.4570, longitude: -112.0710),
        Cafe(id: "sydney", name: "Fréscopa Sydney", neighbourhood: "Sydney", city: "Sydney", region: "NSW",
             street: "201 Sussex St", country: "Australia", cafeRegion: .international, amenities: [.cafe, .showroom],
             hours: .init(7, 19), timeZoneID: "Australia/Sydney", latitude: -33.8700, longitude: 151.2030),
    ]
}
