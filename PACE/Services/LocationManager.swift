import Foundation
import CoreLocation
import Combine

@Observable
final class LocationManager: NSObject {

    // MARK: - Published State

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var gpsAccuracy: GPSAccuracy = .acquiring

    // Live metrics (updated on every GPS fix)
    var rawSpeedMetersPerSecond: Double = 0  // instantaneous, noisy
    var currentPaceSecondsPerMeter: Double = 0  // smoothed rolling average
    var totalDistanceMeters: Double = 0
    var elevationGainMeters: Double = 0
    var elevationLossMeters: Double = 0

    // Route
    private(set) var routeCoordinates: [CLLocationCoordinate2D] = []

    // MARK: - Private State

    private let locationManager = CLLocationManager()
    private var isTracking = false
    private var lastLocation: CLLocation?
    private var lastRecordedLocation: CLLocation?

    // Rolling pace window: last N seconds of speed samples
    private var paceWindow: [(timestamp: Date, speed: Double)] = []
    private let paceWindowSeconds: TimeInterval = 10

    // Elevation
    private var lastAltitude: Double?

    // Minimum distance between recorded route points (reduces noise)
    private let minRoutePointDistance: CLLocationDistance = 5.0

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 2.0  // update every 2 meters
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
    }

    // MARK: - Permissions

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Tracking Control

    func startTracking() {
        guard !isTracking else { return }
        isTracking = true
        resetTrackingState()
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        guard isTracking else { return }
        isTracking = false
        locationManager.stopUpdatingLocation()
    }

    func pauseTracking() {
        locationManager.stopUpdatingLocation()
        // Keep isTracking = true so state is preserved
        lastLocation = nil  // Prevent distance jump on resume
    }

    func resumeTracking() {
        lastLocation = nil
        locationManager.startUpdatingLocation()
    }

    // MARK: - Manual Lap Reset

    func resetLapState() {
        // Called by RunService when a lap is marked
        // (doesn't reset total distance, only lap-level state in RunService)
    }

    // MARK: - Private Helpers

    private func resetTrackingState() {
        routeCoordinates = []
        totalDistanceMeters = 0
        elevationGainMeters = 0
        elevationLossMeters = 0
        currentPaceSecondsPerMeter = 0
        rawSpeedMetersPerSecond = 0
        paceWindow = []
        lastLocation = nil
        lastRecordedLocation = nil
        lastAltitude = nil
    }

    private func processLocation(_ location: CLLocation) {
        let accuracy = GPSAccuracy(horizontalAccuracy: location.horizontalAccuracy)
        gpsAccuracy = accuracy

        // Don't process inaccurate fixes
        guard accuracy.isUsable, location.horizontalAccuracy < 50 else { return }

        // Distance
        if let last = lastLocation {
            let delta = location.distance(from: last)
            if delta > 0 {
                totalDistanceMeters += delta
            }
        }

        // Elevation
        let alt = location.altitude
        if let lastAlt = lastAltitude {
            let diff = alt - lastAlt
            if diff > 0.5 {
                elevationGainMeters += diff
            } else if diff < -0.5 {
                elevationLossMeters += abs(diff)
            }
        }
        lastAltitude = alt

        // Speed + rolling pace
        let speed = max(location.speed, 0)  // speed < 0 means invalid
        rawSpeedMetersPerSecond = speed
        updateRollingPace(speed: speed, at: location.timestamp)

        // Route point
        if let lastRecorded = lastRecordedLocation {
            if location.distance(from: lastRecorded) >= minRoutePointDistance {
                routeCoordinates.append(location.coordinate)
                lastRecordedLocation = location
            }
        } else {
            routeCoordinates.append(location.coordinate)
            lastRecordedLocation = location
        }

        lastLocation = location
        currentLocation = location
    }

    private func updateRollingPace(speed: Double, at timestamp: Date) {
        paceWindow.append((timestamp: timestamp, speed: speed))

        // Trim old samples
        let cutoff = timestamp.addingTimeInterval(-paceWindowSeconds)
        paceWindow.removeAll { $0.timestamp < cutoff }

        guard !paceWindow.isEmpty else { return }

        let averageSpeed = paceWindow.map(\.speed).reduce(0, +) / Double(paceWindow.count)
        if averageSpeed > 0.1 {  // ~0.36 km/h minimum to avoid nonsense pace
            currentPaceSecondsPerMeter = 1.0 / averageSpeed
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }
        // Use the most recent valid fix
        let validLocations = locations.filter { $0.horizontalAccuracy >= 0 }
        guard let latest = validLocations.last else { return }
        processLocation(latest)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError
        if clError?.code == .denied {
            authorizationStatus = .denied
        }
        // Other errors (network unavailable, etc.) are transient — GPS will recover
    }
}
