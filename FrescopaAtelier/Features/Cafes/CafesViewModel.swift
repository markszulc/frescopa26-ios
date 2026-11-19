import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class CafesViewModel {
    enum LoadState: Equatable {
        case loading
        case loaded(CafeDirectory)
        case failed(String)
    }

    enum DisplayMode: String, CaseIterable, Identifiable {
        case list, map
        var id: String { rawValue }
        var title: String { self == .list ? "List" : "Map" }
    }

    private(set) var state: LoadState = .loading
    var region: CafeRegion?
    var requiredAmenities: Set<CafeAmenity> = []
    var displayMode: DisplayMode = .list
    var userLocation: CLLocation?

    private(set) var savedSeats: Set<CafeEvent.ID> = []
    private(set) var seatInFlight: CafeEvent.ID?

    let service: CafeService
    private let now: () -> Date

    init(service: CafeService, now: @escaping () -> Date = { .now }) {
        self.service = service
        self.now = now
    }

    var directory: CafeDirectory? {
        if case .loaded(let directory) = state { return directory }
        return nil
    }

    func load() async {
        if directory == nil { state = .loading }
        do {
            state = .loaded(try await service.loadDirectory())
        } catch is CancellationError {
            return
        } catch {
            if directory == nil { state = .failed("We couldn't load cafés. Pull to try again.") }
        }
    }

    // MARK: Finder

    /// Cafés matching the filters. Nearest first when we know where the user is.
    /// The flagship is featured separately, so it's left out of the list.
    var filteredCafes: [Cafe] {
        let cafes = (directory?.cafes ?? []).filter { cafe in
            !cafe.isFlagship
                && (region == nil || cafe.cafeRegion == region)
                && requiredAmenities.isSubset(of: cafe.amenities)
        }
        guard let userLocation else { return cafes }
        return cafes.sorted { $0.location.distance(from: userLocation) < $1.location.distance(from: userLocation) }
    }

    /// Everything the map shows (filters applied, flagship included).
    var mapCafes: [Cafe] {
        (directory?.cafes ?? []).filter { cafe in
            (region == nil || cafe.cafeRegion == region) && requiredAmenities.isSubset(of: cafe.amenities)
        }
    }

    var resultsTitle: String {
        let count = filteredCafes.count
        let noun = count == 1 ? "café" : "cafés"
        return userLocation == nil ? "\(count) \(noun)" : "\(count) \(noun) near you"
    }

    var hasActiveFilters: Bool { region != nil || !requiredAmenities.isEmpty }

    func toggle(_ amenity: CafeAmenity) {
        if requiredAmenities.contains(amenity) {
            requiredAmenities.remove(amenity)
        } else {
            requiredAmenities.insert(amenity)
        }
    }

    func clearFilters() {
        region = nil
        requiredAmenities = []
    }

    func nearest() -> Cafe? {
        guard let userLocation, let cafes = directory?.cafes else { return nil }
        return cafes.min { $0.location.distance(from: userLocation) < $1.location.distance(from: userLocation) }
    }

    func distanceLabel(for cafe: Cafe) -> String? {
        guard let userLocation else { return nil }
        let meters = cafe.location.distance(from: userLocation)
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let usesMetric = Locale.current.measurementSystem == .metric
        let converted = measurement.converted(to: usesMetric ? .kilometers : .miles)
        return converted.formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                                numberFormatStyle: .number.precision(.fractionLength(converted.value < 10 ? 1 : 0))))
    }

    func openStatus(for cafe: Cafe) -> (label: String, isOpen: Bool) {
        let date = now()
        return (cafe.openStatus(at: date), cafe.isOpen(at: date))
    }

    // MARK: What's on

    /// "Tonight", "Tomorrow" or the weekday name.
    func dayLabel(for event: CafeEvent) -> String {
        let today = Calendar.current.component(.weekday, from: now())
        switch (event.weekday - today + 7) % 7 {
        case 0:
            let parts = Calendar.current.dateComponents([.hour, .minute], from: now())
            let minutesNow = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            if minutesNow >= event.endMinutes { return "Next \(event.weekdayName)" }
            return event.startMinutes >= 17 * 60 ? "Tonight" : "Today"
        case 1: return "Tomorrow"
        default: return event.weekdayName
        }
    }

    func isSaved(_ event: CafeEvent) -> Bool { savedSeats.contains(event.id) }

    func toggleSeat(_ event: CafeEvent) async {
        guard event.requiresBooking, seatInFlight == nil else { return }
        seatInFlight = event.id
        defer { seatInFlight = nil }
        do {
            if savedSeats.contains(event.id) {
                try await service.cancelSeat(for: event.id)
                savedSeats.remove(event.id)
            } else {
                try await service.saveSeat(for: event.id)
                savedSeats.insert(event.id)
            }
        } catch {
            // Leave the seat state unchanged; the user can retry.
        }
    }
}
