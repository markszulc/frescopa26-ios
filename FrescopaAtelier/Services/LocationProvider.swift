import CoreLocation
import Observation

/// Thin, observable wrapper over `CLLocationManager` for "cafés near you".
/// Asks for when-in-use permission only when the user opts in.
@MainActor
@Observable
final class LocationProvider: NSObject {
    enum Status: Equatable { case unknown, requesting, authorized, denied }

    private(set) var status: Status = .unknown
    private(set) var location: CLLocation?

    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        status = Self.map(manager.authorizationStatus)
        if status == .authorized { manager.requestLocation() }
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            status = .requesting
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            status = .authorized
            manager.requestLocation()
        default:
            status = .denied
        }
    }

    private static func map(_ status: CLAuthorizationStatus) -> Status {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: .authorized
        case .denied, .restricted: .denied
        default: .unknown
        }
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let auth = manager.authorizationStatus
        Task { @MainActor in
            let mapped = Self.map(auth)
            // Keep "requesting" until the user actually answers the prompt.
            if !(self.status == .requesting && mapped == .unknown) { self.status = mapped }
            if mapped == .authorized { self.manager.requestLocation() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            self.location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // A one-off failure leaves the list in its default order; nothing to surface.
    }
}
