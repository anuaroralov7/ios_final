import CoreLocation
import Foundation

final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var completion: ((Result<CLLocation, Error>) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        self.completion = completion

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            completion(.failure(NSError(domain: "Location", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location access is disabled. Enable it in Settings."])))
            self.completion = nil
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        @unknown default:
            completion(.failure(NSError(domain: "Location", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown location authorization status."])))
            self.completion = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            completion?(.failure(NSError(domain: "Location", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location access is disabled. Enable it in Settings."])))
            completion = nil
        case .notDetermined:
            break
        @unknown default:
            completion?(.failure(NSError(domain: "Location", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown location authorization status."])))
            completion = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.first {
            completion?(.success(loc))
        } else {
            completion?(.failure(NSError(domain: "Location", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to get current location."])))
        }
        completion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
}
