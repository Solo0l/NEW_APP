import Foundation
import CoreLocation

// @Observable — all property mutations dispatched to main thread from delegate callbacks.

@Observable
final class LocationManager: NSObject {

    // MARK: - Published State (main thread only)

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var gpsAccuracy: GPSAccuracy = .acquiring

    // Smoothed metrics
    var currentPaceSecondsPerMeter: Double = 0
    var totalDistanceMeters: Double = 0
    var elevationGainMeters: Double = 0
    var elevationLossMeters: Double = 0

    private(set) var routeCoordinates: [CLLocationCoordinate2D] = []

    // MARK: - Private

    private let manager = CLLocationManager()
    private var isTracking = false
    private var lastLocation: CLLocation?
    private var lastRecordedLocation: CLLocation?
    private var lastAltitude: Double?

    // Pace: 10-second rolling window of (timestamp, speed) pairs
    private var paceWindow: [(timestamp: Date, speed: Double)] = []
    private let paceWindowDuration: TimeInterval = 10
    private let minRouteSpacing: CLLocationDistance = 5.0

    // MARK: - Init

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2.0
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
        if Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription") != nil {
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
        }
    }

    // MARK: - Permissions

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - Tracking

    func startTracking() {
        guard !isTracking else { return }
        isTracking = true
        reset()
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        manager.stopUpdatingLocation()
    }

    func pauseTracking() {
        manager.stopUpdatingLocation()
        lastLocation = nil  // Prevent distance jump on resume
    }

    func resumeTracking() {
        lastLocation = nil
        manager.startUpdatingLocation()
    }

    func resetLapState() {}

    // MARK: - Private

    private func reset() {
        routeCoordinates = []
        totalDistanceMeters = 0
        elevationGainMeters = 0
        elevationLossMeters = 0
        currentPaceSecondsPerMeter = 0
        paceWindow = []
        lastLocation = nil
        lastRecordedLocation = nil
        lastAltitude = nil
    }

    private func process(_ location: CLLocation) {
        let accuracy = GPSAccuracy(horizontalAccuracy: location.horizontalAccuracy)

        // Reject unusable or very noisy fixes
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy < 50 else {
            gpsAccuracy = .poor
            return
        }

        gpsAccuracy = accuracy

        // Accumulate distance
        if let last = lastLocation {
            let delta = location.distance(from: last)
            if delta > 0 { totalDistanceMeters += delta }
        }

        // Elevation
        if let lastAlt = lastAltitude {
            let diff = location.altitude - lastAlt
            if diff > 0.5 { elevationGainMeters += diff }
            else if diff < -0.5 { elevationLossMeters += abs(diff) }
        }
        lastAltitude = location.altitude

        // Rolling pace
        let speed = max(0, location.speed)
        paceWindow.append((location.timestamp, speed))
        let cutoff = location.timestamp.addingTimeInterval(-paceWindowDuration)
        paceWindow.removeAll { $0.timestamp < cutoff }
        let avgSpeed = paceWindow.map(\.speed).reduce(0, +) / Double(paceWindow.count)
        if avgSpeed > 0.1 { currentPaceSecondsPerMeter = 1.0 / avgSpeed }

        // Route
        let shouldRecord = lastRecordedLocation.map {
            location.distance(from: $0) >= minRouteSpacing
        } ?? true
        if shouldRecord {
            routeCoordinates.append(location.coordinate)
            lastRecordedLocation = location
        }

        lastLocation = location
        currentLocation = location
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Delegate can call on any thread — dispatch to main
        DispatchQueue.main.async { [weak self] in
            self?.authorizationStatus = manager.authorizationStatus
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }
        let validLocations = locations.filter { $0.horizontalAccuracy >= 0 }
        guard let latest = validLocations.last else { return }
        DispatchQueue.main.async { [weak self] in
            self?.process(latest)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            if let clError = error as? CLError, clError.code == .denied {
                self?.authorizationStatus = .denied
            }
            // GPS signal failures are transient; accuracy state already reflects the gap
        }
    }
}
